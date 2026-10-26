#!/bin/bash
# scripts/check_test_leaks.sh — Fail if Godot reports resource leaks at exit.
#
# Usage: bash scripts/check_test_leaks.sh <log-file> [--tolerate-rid=TYPE:MAX_COUNT]...
#                                                     [--tolerate-object-leaks=MAX_COUNT]
#
# Scans the given log file for known leak markers emitted by Godot at engine
# shutdown. These signal that something held a reference to an Object or RID
# beyond the test run — usually an autoload that didn't disconnect signals or
# free children.
#
# --tolerate-rid=TYPE:MAX_COUNT (repeatable) raises the failure threshold for
# one specific --- unexpected RID leaks --- line's TYPE (e.g. a physics shape
# wrapper type) to MAX_COUNT instead of 0. --tolerate-object-leaks=MAX_COUNT
# does the same for the total count of (post-exclusion) "Leaked instance:"
# ObjectDB lines.
# Both exist for callers that already know a specific file's leak count and
# want CI to still catch it growing rather than silence the check outright.
# Prefer fixing the leak; reach for a tolerance only once you've confirmed the
# cause is an engine artifact and recorded why at the call site.
#
# Run the CI test command with -v so that "Leaked instance: TypeName:ID" lines
# appear in the log; this script uses them to distinguish real game object leaks
# from GDScript/GUT baseline noise.
#
# Exits 1 if any real leak is detected, 0 otherwise.

set -euo pipefail

LOG_FILE="${1:?Usage: $0 <log-file> [--tolerate-rid=TYPE:MAX_COUNT]... [--tolerate-object-leaks=MAX_COUNT]}"
shift

declare -A TOLERATED_RID_MAX
TOLERATED_OBJECT_LEAKS=0
for arg in "$@"; do
  case "$arg" in
    --tolerate-rid=*)
      spec="${arg#--tolerate-rid=}"
      TOLERATED_RID_MAX["${spec%%:*}"]="${spec##*:}"
      ;;
    --tolerate-object-leaks=*)
      TOLERATED_OBJECT_LEAKS="${arg#--tolerate-object-leaks=}"
      ;;
    *)
      echo "check_test_leaks: unrecognized argument: $arg" >&2
      exit 2
      ;;
  esac
done

if [[ ! -f "$LOG_FILE" ]]; then
  echo "check_test_leaks: log file not found: $LOG_FILE" >&2
  exit 2
fi

FOUND=0

# --- ObjectDB check ---
# Parse verbose "Leaked instance: TypeName:ID" lines (present when Godot runs
# with -v). Filter out known GDScript/GUT/Godot baseline types. Fail on
# anything with a named class_name (real game objects always declare one).
#
# All exclusions below share the same root cause: Godot's ObjectDB cleanup
# runs before the GDScript runtime tears down its static vars and before
# ResourceLoader flushes its cache. Anything held by a GDScript static var or
# a ResourceLoader-cached resource appears as "leaked" here even though it is
# properly freed moments later. Game objects never fall into this category —
# they are always freed as part of the scene-tree teardown, which runs before
# ObjectDB cleanup.
#
# Excluded types and why:
#   GDScript         — GUT script files without class_name; GDScript holds refs
#                      to every loaded script through its lazy-loader. On Linux
#                      CI these appear as "GDScript", on Windows as
#                      "GDScriptNativeClass". Counts scale with GUT's script
#                      count, not with test code.
#   GDScriptNativeClass — same as above, Windows/older-build variant
#   RefCounted       — anonymous RefCounted (no class_name); game RefCounted
#                      subclasses always have class_name and appear by that name
#   PackedScene      — scene files cached by ResourceLoader (GUT runner scenes,
#                      test fixtures); a real leak of a game scene would be
#                      unusual and would typically involve a named object
#   SceneState       — internal sidecar of PackedScene; always accompanies a
#                      PackedScene leak
#   Theme            — GUT's built-in UI theme, loaded and cached at startup
#   FontFile         — GUT's default theme font; freed after ObjectDB cleanup
#   Image            — internal pixel-data objects owned by CompressedTexture2D
#                      resources cached by ResourceLoader (GUT's red/green/yellow
#                      result-tree icons and logger assets); freed when the
#                      ResourceLoader cache is flushed after ObjectDB cleanup
#   WeakRef          — GUT uses weakref() internally in collected_test.gd and
#                      double_tools.gd to track test scripts and doubles. Game
#                      code should never call weakref(). GUT holds these
#                      wrappers in structures that persist until engine shutdown.
#   StyleBoxFlat     — embedded in GUT's RunExternally.tscn, which is loaded
#                      into GutUtils.RunExternallyScene (a static var) at class
#                      init time; held alive by ResourceLoader cache until after
#                      ObjectDB cleanup
#   ScriptBacktrace  — GUT internal: created whenever push_error() is called
#                      during a test run; stored in GUT's failure result
#                      structures and held alive until engine shutdown
#   Logger           — GUT's internal Logger class; instantiated at GUT startup
#                      and kept alive for the duration of the run. GUT holds it
#                      in a static var, so it outlives ObjectDB cleanup.
#   Mutex            — owned by GUT's Logger instance (one Mutex per Logger);
#                      same root cause and lifetime as Logger above
#   AudioStreamWAV   — Godot built-in audio resource; appears when test
#                      fixtures reference .tres files containing
#                      AudioStreamWAV/AudioStreamRandomizer data that
#                      ResourceLoader caches and does not flush until after
#                      ObjectDB cleanup. These are never game-owned objects at
#                      shutdown — they are engine resource cache entries.
#   AudioStreamRandomizer — same cause as AudioStreamWAV; wraps multiple WAV
#                      streams and is cached alongside them in ResourceLoader
#
# Add to this list only with a verified root cause written alongside it. An
# unexplained entry here hides the next real leak.
if grep -q "ObjectDB instances leaked at exit" "$LOG_FILE" 2>/dev/null; then
  REAL_LEAKS=$(grep -E "^Leaked instance:" "$LOG_FILE" \
    | grep -Ev "GDScript|GDScriptNativeClass|RefCounted|PackedScene|SceneState|Theme|FontFile|Image|StyleBoxFlat|ScriptBacktrace|Logger|Mutex|AudioStreamWAV|AudioStreamRandomizer|WeakRef" \
    || true)
  REAL_LEAK_COUNT=0
  [[ -n "$REAL_LEAKS" ]] && REAL_LEAK_COUNT=$(echo "$REAL_LEAKS" | wc -l)
  if [[ "$REAL_LEAK_COUNT" -gt "$TOLERATED_OBJECT_LEAKS" ]]; then
    echo "::error::Game object leaks detected (ObjectDB): $REAL_LEAK_COUNT (tolerated: $TOLERATED_OBJECT_LEAKS)"
    echo "$REAL_LEAKS" | head -20
    FOUND=1
  fi
fi

# --- RID check ---
# Filter out DummyTexture, DummyShader, and FontAdvanced (headless rendering
# baseline — RendererDummy/TextServerAdvanced fallback types created by
# GUT's headless rendering context regardless of test content; DummyShader
# is Linux-CI-only, not observed on Windows). Real game RID leaks
# (ENetPacketPeer, custom types, etc.) still fail the build.
RID_LINES=$(grep -E "RID allocations of type|RIDs of type .* were leaked" "$LOG_FILE" \
  | grep -Ev "DummyTexture|DummyShader|FontAdvanced" || true)
UNTOLERATED_RID_LINES=""
if [[ -n "$RID_LINES" ]]; then
  while IFS= read -r line; do
    rid_type=$(echo "$line" | grep -oE "'[^']+'" | tr -d "'")
    rid_count=$(echo "$line" | grep -oE "[0-9]+" | head -1)
    max="${TOLERATED_RID_MAX[$rid_type]:-0}"
    if [[ -z "$rid_count" || "$rid_count" -gt "$max" ]]; then
      UNTOLERATED_RID_LINES+="$line"$'\n'
    fi
  done <<< "$RID_LINES"
fi
if [[ -n "$UNTOLERATED_RID_LINES" ]]; then
  if [[ $FOUND -eq 0 ]]; then
    echo "::error::Resource leak warnings detected in test output:"
  fi
  echo "--- unexpected RID leaks (excluding headless baseline types and tolerated counts):"
  echo "$UNTOLERATED_RID_LINES" | head -10
  FOUND=1
fi

if [[ $FOUND -ne 0 ]]; then
  echo
  echo "Tests passed but Godot reported leaked resources at engine shutdown."
  echo "Likely cause: an autoload kept references via signal connections or"
  echo "child nodes after _exit_tree. Add explicit cleanup in the offending"
  echo "autoload."
  exit 1
fi
