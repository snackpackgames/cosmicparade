#!/bin/bash
# scripts/ensure-godot.sh — Download and cache the project's pinned Godot
# version if it isn't already available, and write .env's GODOT= line so
# scripts/test.sh, scripts/import.sh, etc. work without any manual setup.
#
# Intended for disposable sandboxes (cloud agent runs) that have no
# persistent .env — CI instead uses chickensoft-games/setup-godot@v2, and a
# local dev machine should just set GODOT in its own .env per .env.example.
#
# Usage: bash scripts/ensure-godot.sh

set -euo pipefail

GODOT_VERSION="4.6.1"
GODOT_TAG="${GODOT_VERSION}-stable"
GODOT_ASSET="Godot_v${GODOT_TAG}_linux.x86_64.zip"
GODOT_URL="https://github.com/godotengine/godot/releases/download/${GODOT_TAG}/${GODOT_ASSET}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CACHE_DIR="${GODOT_CACHE_DIR:-$HOME/.cache/godot-cosmicparade}"
BINARY_PATH="$CACHE_DIR/Godot_v${GODOT_TAG}_linux.x86_64"

# Already resolvable (e.g. a previous run in the same sandbox already did this)?
if [[ -f "$PROJECT_ROOT/.env" ]] && grep -q '^GODOT=' "$PROJECT_ROOT/.env"; then
  existing="$(grep '^GODOT=' "$PROJECT_ROOT/.env" | head -1 | cut -d= -f2- | tr -d '"')"
  if [[ -x "$existing" ]]; then
    echo "GODOT already configured in .env: $existing"
    exit 0
  fi
fi

if [[ ! -x "$BINARY_PATH" ]]; then
  echo "Downloading Godot ${GODOT_VERSION} (linux x86_64) to $CACHE_DIR..."
  mkdir -p "$CACHE_DIR"
  curl -fsSL "$GODOT_URL" -o "$CACHE_DIR/godot.zip"
  unzip -oq "$CACHE_DIR/godot.zip" -d "$CACHE_DIR"
  rm -f "$CACHE_DIR/godot.zip"
  chmod +x "$BINARY_PATH"
fi

# Preserve any other existing .env lines (if any) — only replace/add GODOT=.
if [[ -f "$PROJECT_ROOT/.env" ]]; then
  grep -v '^GODOT=' "$PROJECT_ROOT/.env" > "$PROJECT_ROOT/.env.tmp" || true
  mv "$PROJECT_ROOT/.env.tmp" "$PROJECT_ROOT/.env"
fi
echo "GODOT=\"$BINARY_PATH\"" >> "$PROJECT_ROOT/.env"

echo "Godot ready: $BINARY_PATH"
"$BINARY_PATH" --version
