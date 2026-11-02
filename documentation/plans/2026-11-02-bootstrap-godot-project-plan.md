# Bootstrap the Godot project

Implementation plan for milestone **M0: Project bootstrap**, handed off from
[Map: bootstrap the Godot project](https://github.com/snackpackgames/cosmicparade/issues/2).

This repo holds tooling, CI, lint config, the design document and its ADRs, and **no
Godot project**. At the end of this plan `project.godot` exists and carries the settings
the map decided, GUT runs, two tests pass, and no document in the repo still claims the
project is unbuilt.

Every decision below was settled on the map. Where this plan says "decided", the linked
ticket holds the reasoning — do not re-derive it, and do not substitute a different
answer because it looks better in context.

## Phases

| Phase | Issue | Delivers |
|---|---|---|
| 1 | The project exists and boots | Engine pin, vendored GUT, `project.godot`, main scene, shared shader |
| 2 | The suite proves something | Two tests, the zero-test guard, CI wired |
| 3 | The documentation stops lying | ADR 0013, `CLAUDE.md`, `CONTRIBUTING.md`, the pin sweep's prose |

Phase 2 is blocked by phase 1; phase 3 is blocked by phase 2. Commit after each task, as
each phase's issue directs.

---

## Phase 1 — The project exists and boots

### Task 1.1 — Pin the engine to 4.7.2-stable where it is load-bearing

[Decided](https://github.com/snackpackgames/cosmicparade/issues/13): `4.7.2-stable`, the
latest 4.7. It has `SCALING_3D_MODE_NEAREST`, which makes a consistent on-screen tessera
size two project settings instead of a hand-built `SubViewport` pipeline.

Four files, all of which something executes:

- `.github/workflows/godot-ci.yml` — the `GODOT_VERSION` env value **and** the
  `chickensoft-games/setup-godot@v2` `version:` input. Both currently read `4.6.1`.
- `.github/workflows/claude.yml` — the `version:` input.
- `scripts/ensure-godot.sh` — `GODOT_VERSION="4.6.1"`.
- `.env.example` — the "Godot 4.6+" comment.

**Verify `chickensoft-games/setup-godot@v2` resolves 4.7.2 before going further.** If it
cannot, stop and report it on the issue rather than pinning a version CI can't install —
a silently different engine in CI than on a developer's machine is worse than a red
build. Prose mentions of 4.6 in `CLAUDE.md`, `CONTRIBUTING.md`, the aseprite skill and
the routine prompt are **phase 3's** work; this task touches only what executes.

### Task 1.2 — Vendor GUT v9.7.1 under `addons/gut/`

[Decided](https://github.com/snackpackgames/cosmicparade/issues/6), and the acquisition
route matters more than it looks:

- Take the **`v9.7.1` tag**. GUT's `main` branch *is* the 4.6.x line — not a development
  line — and the Asset Library carries only v9.6.1 (4.6.x), so both obvious install
  routes give an engine mismatch.
- Commit the whole `addons/gut/` directory, **including `.uid` sidecars**. CI installs no
  addons and `actions/checkout` does not pass `submodules: true`, so a vendored copy is
  forced rather than chosen.
- Nothing else in the repo needs changing to accommodate it: `scripts/lint.sh` already
  excludes `./addons/*`, `.gitignore` does not exclude it, and `.gdlintrc` already lists
  `GutTest` under `ignored-classes`.

Enable the plugin in `project.godot` (task 1.3) via
`[editor_plugins] enabled=PackedStringArray("res://addons/gut/plugin.cfg")`. On the
evidence this is editor-only — the CLI entry point `addons/gut/gut_cmdln.gd` does not
check it — but enable it anyway so the editor's GUT panel works for humans.

### Task 1.3 — Write `project.godot`

Every value below is decided. The renderer and window keys come from
[the renderer ticket](https://github.com/snackpackgames/cosmicparade/issues/5), the layer
names from [the layer table](https://github.com/snackpackgames/cosmicparade/issues/7),
and `run/main_scene` from
[the main scene ticket](https://github.com/snackpackgames/cosmicparade/issues/8).

```ini
[application]
config/name="Cosmic Parade"
config/features=PackedStringArray("4.7", "Forward Plus")
config/icon="res://icon.svg"
run/main_scene="res://ui/title/title.tscn"

[editor_plugins]
enabled=PackedStringArray("res://addons/gut/plugin.cfg")

[display]
window/size/viewport_width=1920
window/size/viewport_height=1080
window/stretch/mode="canvas_items"
window/stretch/aspect="expand"

[layer_names]
3d_physics/layer_1="realm_space"
3d_physics/layer_2="furniture"
3d_physics/layer_3="fixture"
3d_physics/layer_9="biome_ground"
3d_physics/layer_10="terrain_feature"
3d_physics/layer_17="entity"
3d_physics/layer_25="parade_space"
3d_physics/layer_26="tile"

[rendering]
renderer/rendering_method="forward_plus"
scaling_3d/mode=<SCALING_3D_MODE_NEAREST ordinal>
scaling_3d/scale=1.0
anti_aliasing/quality/msaa_3d=<MSAA_4X ordinal>
anti_aliasing/quality/screen_space_aa=0
anti_aliasing/quality/use_taa=false
```

**The two ordinals must be confirmed against the 4.7 class reference**
(`Viewport.Scaling3DMode`, `Viewport.MSAA`) rather than guessed. Phase 2's settings test
asserts them through the named constants, so a wrong ordinal fails loudly there — but
finding it in phase 1 is cheaper.

Also set the **project-wide image Import Defaults**: Lossless compression, VRAM
compression **off**, mipmaps **on**. The docs require VRAM compression off for pixel art
and say so explicitly including for 3D, and mipmaps are required for
`NEAREST_WITH_MIPMAPS` filtering to do anything. Confirm the `[importer_defaults]`
texture key names against 4.7 before writing them.

Leave `rendering/environment/defaults/default_environment` empty — shipping an
environment means authoring the cosmic skybox, which is the first visual 3D scene and
out of scope.

Write **no `[autoload]` section at all**, not even an empty one
([decided](https://github.com/snackpackgames/cosmicparade/issues/9)).

### Task 1.4 — Keep Godot's default `icon.svg`

Commit `icon.svg` and `icon.svg.import` as the engine generates them, per
`CLAUDE.md` → Common Gotchas. [Decided](https://github.com/snackpackgames/cosmicparade/issues/8):
it is visibly not ours, so nobody mistakes it for a decision, and the art direction gets
a real pass later. Do not author a placeholder mark.

### Task 1.5 — The main scene: `ui/title/title.tscn`

A stub of the real Title screen, not a boot root
([decided](https://github.com/snackpackgames/cosmicparade/issues/8)). `ui/title/` is where
screens live, since screens are not systems
([decided](https://github.com/snackpackgames/cosmicparade/issues/3)).

- Root node `Title`, a `Control` with full-rect anchors.
- `ui/title/title.gd` beside it, declaring `class_name Title`.
- Shows the game's name, and under it a small line composed in `_ready()` from
  `RenderingServer.get_current_rendering_method()`, `Engine.get_version_info()` and the
  viewport size:

  ```
          Cosmic Parade

    forward_plus · 4.7.2.stable · 1920×1080
  ```

- **Read those values at runtime, not from `ProjectSettings`.** Godot's
  `rendering/rendering_device/fallback_to_*` settings let a Forward+ project come up in
  Compatibility on hardware that cannot serve it, and until there is 3D geometry this
  line is the only thing that would reveal a degraded boot. Reading the settings back
  would echo the request rather than the result.
- No theme, no `ui/theme/` directory, default font. No input handling — the `[input]`
  action set is out of scope.
- Not debug-gated: it is a stub the real Title screen replaces, and there is no release
  build to hide it from.

Commit the `.uid` sidecars for both files.

### Task 1.6 — The shared surface shader: `common/surface.gdshader`

`common/` is the structural directory for cross-cutting source — code that more than one
system uses and no system owns
([decided](https://github.com/snackpackgames/cosmicparade/issues/14)).

```glsl
shader_type spatial;

uniform sampler2D albedo_texture : source_color, filter_nearest_mipmap;
```

Why this exists rather than a per-material convention
([decided](https://github.com/snackpackgames/cosmicparade/issues/5)): Godot has no
project-wide 3D texture filter — it is `BaseMaterial3D.texture_filter` per material — so
baking the filter into the sampler hint is what stops it drifting. Constraints:

- Write only `ALBEDO`. A spatial shader that writes no `light()` function still gets
  Godot's built-in lighting, shadows and ambient contribution, so this is a thin wrapper
  and not a hand-rolled lighting model.
- `source_color` is **required** on an albedo sampler in Forward+.
- Do **not** use `unshaded`: terrain that grows out of the board needs shading to read
  its height.

This file ships now even though no mesh uses it yet, deliberately against the
"arrives with its content" pattern the map applied elsewhere, because it is the guardrail
— whoever adds the first mesh otherwise reaches for a `BaseMaterial3D` filter setting and
the drift starts with the first mesh rather than the tenth.

No `ShaderMaterial` `.tres` ships with it.

### Task 1.7 — Verify the boot

```bash
bash scripts/import.sh        # rebuild the class cache; Title is a new class_name
```

Then confirm the project opens and the main scene loads without error. `gdlint` must pass
(`bash scripts/lint.sh`) — note `.gdshader` files are not linted, since `scripts/lint.sh`
matches `*.gd` only.

**CI at the end of phase 1 will run GUT and report zero tests**, because `test/unit/` is
still empty. That is expected and is exactly what phase 2 closes.

---

## Phase 2 — The suite proves something

### Task 2.1 — `test/unit/ui/title/test_title.gd`

Mirrors `ui/title/title.gd` under the mirror rule. Load `res://ui/title/title.tscn`,
instantiate it, parent it with `add_child_autofree` so `_ready()` actually runs, and
assert the environment line was composed — **non-empty text, not a specific value**.

CI runs `--headless`, where the dummy rendering driver is in play, so what
`get_current_rendering_method()` reports there is not what a contributor sees at F5.
Asserting the value would pin the wrong thing; the configured value is task 2.2's job.

### Task 2.2 — `test/unit/test_project_settings.gd`

At the **root** of `test/unit/`, not in a mirror directory: its subject is
`project.godot`, and the mirror rule governs tests of source files. `.gutconfig.json`
collects `res://test/unit/` with `include_subdirs`, so a root-level file runs with the
rest.

Pin every value phase 1 wrote: `run/main_scene`, `renderer/rendering_method`,
`scaling_3d/mode` and `scale`, `msaa_3d`, `screen_space_aa`, `use_taa`, the window size,
stretch mode and aspect, and **all eight `layer_names/3d_physics/layer_N` names**.

- **Use the named constants** (`Viewport.SCALING_3D_MODE_NEAREST`, `Viewport.MSAA_4X`),
  not integers. This is what backstops the ordinals in task 1.3.
- The layer names are why this pins hard: other code will encode those bits numerically,
  so a renumber breaks nothing loudly — it just makes every mask point elsewhere.
- **State in a comment** that `ProjectSettings.get_setting()` returns the engine default
  for a key absent from `project.godot`, so pinning `screen_space_aa` or `use_taa` proves
  the effective configuration rather than the file's contents. That is the right thing to
  assert — the effective value is what renders — but it is not a file-content check.
- Do **not** assert the other 24 layer bits are empty. That would fail the first time
  someone legitimately claims bit 4 inside the realm block, which the table invites.

### Task 2.3 — Delete `test/unit/.gitkeep`

It exists only so `-gdir=res://test/unit/` resolves against an empty directory. With two
test files present it contradicts the no-`.gitkeep` rule from the layout decision.

### Task 2.4 — `scripts/check_test_count.sh` and its CI step

The guard that cannot be a test. `addons/gut/gut_cmdln.gd` calls `quit(0)` when GUT's own
`class_name`s are missing from the class cache, **before any test runs**, so a test
asserting the cache is warm can never execute
([found here](https://github.com/snackpackgames/cosmicparade/issues/6)).

A sibling to `scripts/check_test_leaks.sh`, taking the JUnit report path. **Two cases,
both must fail:**

- The report exists and reports zero tests — an empty or fully-skipped suite.
- **The report does not exist at all** — which is what a cold-cache `quit(0)` produces,
  since GUT never reaches the point of writing `-gjunit_xml_file`.

Add it to `.github/workflows/godot-ci.yml` as a step after *Run GUT tests*, guarded the
same way the leak check is (`! cancelled()` plus the probe's `runnable == 'true'`).

**Leave the probe step in place.** Nothing on the map asked for its removal, and it still
guards a partial checkout; removing it would be scope the handoff did not carry.

Optionally add `-gjunit_xml_file` to the all-tests branch of `scripts/test.sh` so the
guard is runnable locally too — `.gitignore` already carries `**/test_results.*` and
`test_output.log`, so the scaffold anticipated writing them.

### Task 2.5 — Verify

```bash
bash scripts/test.sh
bash scripts/check_test_count.sh <report path>   # expect pass
```

Two test scripts collected, every test passing, and the count guard green. After this
phase a green badge means four things: the project boots, its settings are the ones
decided, no leaks, and the suite actually ran.

---

## Phase 3 — The documentation stops lying

### Task 3.1 — ADR 0013

`documentation/adr/0013-repo-layout-follows-area-labels.md`. One ADR, not four
([decided](https://github.com/snackpackgames/cosmicparade/issues/11)).

It argues the **`area:` label set as the project's single system vocabulary**, and the
**two categories of top-level directory** that the label rule alone does not describe
([decided](https://github.com/snackpackgames/cosmicparade/issues/14)): system
directories named after labels, and structural directories named for what they hold as a
closed enumerated list.

Record what was rejected: grouping by node kind, and a `src/` umbrella. Cite the physics
layers, the autoload rule and the `GameData` base as consequences of the vocabulary
rather than re-arguing them. **Do not restate the directory tree** — `CLAUDE.md` holds
the rule, the ADR holds the why.

### Task 3.2 — `CLAUDE.md`

| Section | Change |
|---|---|
| Project Overview | "built with **Godot 4.6**" → `4.7.2-stable` |
| Status: scaffold only | Premise dies on merge. **Rewrite as the real status** — keep the section, since the CI probe's step summary links to it |
| Running and Testing | The `combat/hitbox.gd` mirror example is a `fiber` system; restate against a real `area:` name, e.g. `tiles/tile_slot.gd` → `test/unit/tiles/test_tile_slot.gd` |
| Running and Testing (CI line) | "Godot 4.6.1" → `4.7.2` |
| Local Setup | "Godot 4.6+ executable path" → 4.7+ |
| Conventions | Refine the data-in-Resources line with the `GameData` base and `data/<system>/<type>/<instance>.tres` |
| Conventions | Add the one documented exception: **an autoload script declares no `class_name`**, since it collides with the singleton name |
| Architecture | Placeholder → the directory table (system vs structural, with the `test/unit/` mirror column and the note that `scripts/` holds bash, not GDScript), the autoload threshold and `SignalBus` charter, the `GameData` convention, and a pointer to ADR 0013 |
| 3D Physics Layers | TODO block and its implied-roles bullets → the layer table, which supersedes them. Keep the rule, reworded: pick the layer/mask combination matching a new body's role, and if none fits, claim the next bit **inside that role's block** and add a row in the same change. Record that domain influence gets **no layer** — it is hex-grid data — so nobody fills the gap ad hoc |

### Task 3.3 — `CONTRIBUTING.md`

| Section | Change |
|---|---|
| Repo setup (still pending) | Wrong in three ways — see below |
| Tests | Same `combat/hitbox.gd` example |
| Local environment (`.env`) | The `GODOT` row's "Godot 4.6+" and the `Godot_v4.6.1-stable_linux.x86_64` example path |
| PR metadata | Drop the "Setup still pending" note claiming the repo has only default labels, no milestones and no board |

The Repo setup checklist:

1. **Two items this plan completes** — the Godot project, and `addons/gut/`.
2. **The Godot project item names the wrong files.** It lists "`project.godot`,
   `main.tscn`, `icon.svg`"; there is no `main.tscn` — the main scene is
   `ui/title/title.tscn` — and `icon.svg` is Godot's own default, kept rather than
   created.
3. **Five items already exist and are listed as pending.** Verified 2026-10-31: the area
   and type labels, all eight milestones, the `Cosmic Parade v1.0` board (project 2, with
   all seven `Status` options), the triage labels, and the wayfinder labels.

What genuinely remains afterwards: `export_presets.cfg` and the `CLAUDE_CODE_OAUTH_TOKEN`
secret, both out of scope on the map.

### Task 3.4 — The prose half of the pin sweep

- `.claude/skills/aseprite/SKILL.md` — "a **3D** Godot 4.6 project". Project-owned, so
  safe to edit (unlike `.claude/skills/wayfinder/`, which is vendored and must not be
  touched).
- `documentation/agents/scheduled-routine-prompt.md` — "this is a Godot 4.6 / GDScript
  project".

**The routine prompt needs a manual step this agent cannot perform.** That file is
authoritative but not live: the running routine is configured in Claude Code's
`/schedule`, which nothing in the repo can reach. Say so in the PR body so the maintainer
re-pastes it; without that, the file and the running routine drift.

### Task 3.5 — Verify

`bash scripts/lint.sh` and `bash scripts/test.sh` both pass, and no file in the repo still
asserts that the Godot project does not exist.

---

## What this plan does not do

Ruled out of scope on the map, and not to be added opportunistically:

- **The first visual 3D scene** — camera, skybox, placeholder board geometry.
- **Parade ground geometry** — hex versus a mixed-polygon tiling.
- **`export_presets.cfg`, desktop packaging and build CI.**
- **The `[input]` action set** — camera orbit, pointer pick, confirm/cancel.
- **`documentation/ARCHITECTURE.md`** — it waits for a second system to cross-reference
  ([decided](https://github.com/snackpackgames/cosmicparade/issues/11)).
- **`common/game_data.gd` and the data-validation test** — they arrive with the first
  authored `.tres` ([decided](https://github.com/snackpackgames/cosmicparade/issues/10)).
- **Any autoload**, including an empty `SignalBus`
  ([decided](https://github.com/snackpackgames/cosmicparade/issues/9)).
