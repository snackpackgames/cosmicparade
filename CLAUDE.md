# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Cosmic Parade is a **3D** game built with **Godot 4.6** using **GDScript**.

**Genre:** mosaic deckbuilding · pet management · cozy sandbox room decorator ·
crafting. Two halves that feed each other — a cozy realm-tending half (decorate, grow,
cook, befriend) and a competitive tile-laying half where what you made becomes a deck
played against other gods.

**Core loop:** arrange furniture → furniture projects domain influence → overlapping
influence melds or burgeons into fused biomes and terrain → grow fruit and flowers →
offer fruit at shrines → entities arrive, wander and bond → at the Altar, summon
entities and fire tiles they glaze → tiles fill bags and decks → parade out to play a
pageant → win adherents and materials → Swell the realm, unlock new clays and dyes,
attract stronger entities. Progression pressure comes from the top end: stronger
entities want better offerings, which want more specific fused domains, which want more
furniture and a bigger realm.

**Art direction:** pixel art styled to look like laid mosaic tile — a higher pixel
count per sprite than classic pixel art, but everything reads as tesserae. Floating
rocks against a shifting skybox of cosmic dust and plasma. Neon magical gnomes in
space; science, tech and magic meet in high fantasy. **This is a 3D game** — the
pixel-mosaic look sits on 3D geometry, the hex board has real dimension, and terrain
grows up out of it (see `documentation/adr/0001`).

**`README.md` at the repo root is the authoritative design document** — scenes,
pageant rules, systems, settled decisions and open questions. Read it before design
work. `documentation/adr/` records why each settled decision went the way it did.

## Status: scaffold only

This repo currently holds project configuration ported from the `fiber` project —
tooling scripts, CI, lint/format config, Claude Code skills and conventions — plus the
design document (`README.md`) and its decision records (`documentation/adr/`), and
**no Godot project yet**. `CONTRIBUTING.md → Repo setup` lists what is still missing
(`project.godot`, `addons/gut/`, labels, milestones, project board). Commands below
that invoke Godot or GUT will not work until those exist.

## Running and Testing

- **Run the game**: Open in Godot Editor and press F5
- **Run tests (CLI)**: Use the wrapper scripts in `scripts/`. These auto-detect the project root and read the Godot path from `.env`:
  - Run all tests: `bash scripts/test.sh`
  - Run a specific subsystem: `bash scripts/test.sh <dir>` (e.g., `bash scripts/test.sh combat`)
  - Run a single test file: `bash scripts/test.sh <path/to/test_file.gd>`
  - **Path convention**: `scripts/test.sh` auto-prepends `test/unit/` — pass paths relative to that dir (e.g., `mob/test_foo.gd`, not `test/unit/mob/test_foo.gd`)
- **After adding a new `class_name` script**, rebuild the class cache before running tests:
  ```
  bash scripts/import.sh
  ```
- **Unloadable test scripts fail the run**: GUT on its own silently drops a test file that fails to parse (or preloads something that does). `test/hooks/pre_run_hook.gd` (configured in `.gutconfig.json`) catches these and reports each one as a failure of `test_all_test_scripts_load` — look for the file's `Parse Error` earlier in the log
- **Tests use the [GUT](https://github.com/bitwes/Gut) framework**. Tests live in `test/unit/` and extend `GutTest`. Test files mirror the source tree — e.g., `combat/hitbox.gd` → `test/unit/combat/test_hitbox.gd`
- **CI**: GitHub Actions runs gdlint then GUT tests on PRs/pushes to `main` using Godot 4.6.1 via `chickensoft-games/setup-godot@v2`

### Local Setup

The project uses a `.env` file (gitignored) for machine-specific configuration. Copy `.env.example` to `.env` and set the `GODOT` variable to your Godot 4.6+ executable path. The wrapper scripts in `scripts/` read this file automatically.

**If `.env` is missing or `GODOT` is not set**, ask the user for their Godot executable path and create the `.env` file:
```
GODOT="/path/to/godot/executable"
```

**In a disposable sandbox with no interactive user to ask** (e.g. a cloud agent run), run `bash scripts/ensure-godot.sh` instead — it downloads the project's pinned Godot version (matching CI's `chickensoft-games/setup-godot@v2` version) into a cache directory and writes `.env` itself.

**Install the pre-push lint hook** if it is not already present — check once at the start of each session and install silently if missing:
```bash
# Check
test -f .git/hooks/pre-push || bash scripts/install-hooks.sh
```
This ensures `gdlint` runs locally before every push, matching what CI enforces.

**Install both skill plugins** so all skills appear in every Claude Code session. Run these from the project root — also re-run if the project folder has ever been moved or renamed:

```
# One-time per machine — registers the snackpackgames marketplace
/plugin marketplace add snackpackgames/snackpackgames-claude-plugins

# Install both plugins (run from project root)
/plugin install superpowers@claude-plugins-official
/plugin install snackpackgames-claude-plugins@snackpackgames
```

If Godot skills (`godot-combat-system`, etc.) or superpowers skills (`writing-plans`, `requesting-code-review`, etc.) are absent from the session-start system-reminder, the plugins were likely installed for a different project path (e.g., after a folder rename). Re-running the two install commands above fixes it.

See `CONTRIBUTING.md → AI Tooling` for full setup including optional Godot MCP configuration.

## Common Gotchas

- **Lambda captures**: GDScript lambdas copy local variables at capture time — they do not reference them. To capture mutable state from signal callbacks in tests, use a container (Array or Dictionary) instead of a plain variable.
- **Autoload type hints**: Autoload signal bus scripts cannot type-hint `class_name` types that may not be loaded yet. Use untyped parameters for signals that reference custom `RefCounted` subclasses.
- **New `class_name` registration**: After adding a new `class_name` declaration, run `--import` (see above) to rebuild the global script class cache before running tests. Without this step, GUT will not recognize the new type.
- **`add_child` before `global_position`**: Setting `global_position` on a node not yet in the tree sets its local `position` instead; the parent transform is then applied on top. Always `add_child()` first.
- **`.uid` and `.import` files must be committed**: Godot generates `.uid` sidecars alongside scripts and assets, and `.import` sidecars alongside every imported asset (models, textures, audio). Neither is gitignored and both must be checked in — `.uid` lets Godot reference files by stable ID even after a move, and `.import` carries the import settings for that asset. A missing `.import` means every contributor and CI re-imports with defaults, which silently changes how a model or texture looks. Always include them when committing new scripts or assets.

## Architecture

**Nothing is built yet** — there is no `project.godot`, no entry point and no
directory layout to document. Do not infer one from this section; it records only what
the design already commits to.

The design's scene list (`README.md → Scenes`) is what the layout will have to carry:
Title → Character Creation → Realm (shrines, furniture, Altar with Summon and Fire,
Shipyard Mooring) → Cosmic Parade (pageants on a parade ground). The Realm and the
Cosmic Parade are the two heavyweight scenes and the two halves of the game.

Two structural decisions already constrain how systems get written:

- **Data in Resources, logic in scripts** (existing convention, below) is load-bearing
  for three systems in particular. The fusion lookup table (`adr/0004`), tile slot
  assembly (`adr/0006`) and per-entity glaze lists (`adr/0007`) are all `.tres` data
  with no per-instance authoring.
- **Terrain generation is two systems, not one** — biome fill across overlap interiors,
  and feature spawning on boundaries (`adr/0008`).

Fiber kept architecture as a table of system docs under `documentation/` plus a
`documentation/ARCHITECTURE.md` for directory and resource conventions — worth
repeating here once there is a second system to cross-reference.

`documentation/plans/` holds implementation plan files for features in progress. When resuming work on a feature, check here for the step-by-step plan before touching code.

`documentation/adr/` holds architecture decision records.

### 3D Physics Layers

> **TODO: no layers are assigned yet** — there is no `project.godot` to assign them
> in. Assign and document layer names there under `[layer_names]`
> (`3d_physics/layer_N`) before adding the first collision body, then record the
> assignments as a table here. Pick the layer/mask combination that matches a new
> body's role rather than introducing new bits ad hoc.

The design implies these distinct collision roles, listed to inform that first
assignment — **this is not a layer table and nothing is reserved yet**:

- Board spaces that accept a tile placement (realm hex spaces; parade ground spaces)
- Placed tiles and furniture as volumes (`adr/0001`)
- Domain influence zones, which overlap on purpose and need overlap queries
- Walkable biome ground, versus blocking terrain features (`adr/0008`)
- Roaming entities, and the player's pointer or camera picking against all of the above

Note that domain influence zones exist to overlap — several at once, by design — so
whatever carries them must tolerate many simultaneous overlaps rather than treating
one as a collision to resolve.

Godot gives 3D physics its own 32 layers, independent of the 2D set. `Area3D`,
`StaticBody3D`, `CharacterBody3D` and `RigidBody3D` all read `collision_layer`
(what I am) and `collision_mask` (what I detect) from that 3D set — a layer
number means nothing on its own until it is named in `project.godot`.

### Notes Directory

`notes/` contains in-progress research, code review findings, dev notes, and other working material. **Notes are not a finalized source of truth** — treat them as useful context and background, not authoritative specs. For authoritative specs, use `README.md` (game design) and `documentation/`. Check `notes/` before starting work on a feature to surface relevant history or open questions.

## Conventions

- Classes use `class_name` declarations for engine-wide type registration
- `@export` for editor-tunable properties, `@onready` for node references
- `%NodeName` syntax for unique node access in scenes
- Scene files (`.tscn`) are paired with scripts (`.gd`) in the same directory or a `/scenes/` subdirectory
- Data definitions use Godot Resources (`.tres`), logic lives in scripts
- Use full `snake_case` words for variable and parameter names — avoid cryptic abbreviations like `rr`/`rv`/`sa`/`ea`/`inst`/`def`/`rs`. Prefer `roll_range`, `rolled_value`, `stat_affix`, `effect_affix`, `instance`, `definition`, `rolled_stat`. Short loop counters (`i`, `j`) and established project-wide terms (e.g. `mod` for `StatModifier`) are fine.

## Claude Code Configuration

**Never use git worktrees for this project.** Do not invoke `EnterWorktree` or `git worktree add` — even when skills like `subagent-driven-development` suggest it. Worktrees cause two problems here: (1) the pre-push lint hook runs from the main repo root, so new files go unlinted locally while CI catches them; (2) Claude Code re-prompts for every permission that was already approved. Work on feature branches directly in the main working directory instead.

**Always construct branch names per `CONTRIBUTING.md → Branches`.** Never accept or fall back to an auto-generated codename branch (e.g. `claude/charming-faraday-37tkyg`) — always use one of the topic prefixes (`feature/`, `fix/`, `docs/`, `research/`), fuse the issue number into the slug when one exists, and follow the slug rules (kebab-case, 5 words max, no generic filler slugs like `misc` or `cleanup`).

- `.claude/memory/` — Shared, version-controlled memory files for Claude Code context across sessions (see below)
- `.claude/commands/` — Custom slash commands (user-invoked with `/command-name`)
- `.claude/skills/` — Project-owned skills, plus skills vendored from `mattpocock/skills` (mirrored in `.agents/skills/`, tracked by `skills-lock.json`)
- `snackpackgames/snackpackgames-claude-plugins` — Claude Code plugin providing all Godot/Nakama skills (install via `/plugin install`, see above)
- `.claude/settings.json` — Shared Claude Code settings (checked in)
- `.claude/settings.local.json` — Local-only settings (gitignored, machine-specific)

### Shared Memory (`.claude/memory/`)

The `.claude/memory/` directory contains **project-level, version-controlled** memory files that persist context across Claude Code sessions. These are checked into the repo and shared with all contributors using Claude Code.

- `MEMORY.md` — Index file listing all memory entries (one line each, loaded into every conversation)
- Individual `.md` files — Each memory has YAML frontmatter (`name`, `description`, `metadata.type`) and a body explaining the rule/fact, why it matters, and how to apply it

This is distinct from the **user-level** memory directory (`~/.claude/projects/<project>/memory/`), which is per-user and not version-controlled. Project-level memories should capture shared knowledge — conventions, gotchas, and feedback that applies to anyone working on the project. User-specific preferences belong in user-level memory instead.

### Skills (`snackpackgames/snackpackgames-claude-plugins`)

Skills are installed as a Claude Code plugin — they appear in the session-start system-reminder and Claude invokes them autonomously based on context. Install the plugin once per machine (see above).

**Trigger table — Claude should invoke these skills when working on the described tasks.** The folder column is left to be filled in as the project's directory layout settles.

The plugin's Godot skills were written for a 2D project, so the 2D-only ones
(`godot-2d-animation`, `godot-2d-physics`, `godot-characterbody-2d`,
`godot-tilemap-mastery`) are **left out of this table** — their APIs
(`AnimatedSprite2D`, `Area2D`, `CharacterBody2D`, `TileMap`) have no bearing on a
3D scene, and reading them invites 2D-shaped answers. There is no 3D counterpart
skill for physics, character movement or animation, so those areas have no skill
coverage here: work them from the Godot docs rather than from a 2D skill.

| Skill | Auto-invoke when... |
|---|---|
| `godot-ability-system` | Implementing or modifying abilities, cooldowns, or action executors |
| `godot-adapt-single-to-multiplayer` | Converting single-player systems to multiplayer-aware |
| `godot-animation-player` | Using `AnimationPlayer` tracks, callbacks, or RESET animations |
| `godot-animation-tree-mastery` | Using `AnimationTree`, blend spaces, root motion, or state machine transitions |
| `godot-audio-systems` | Implementing sound effects, music, audio buses, or `AudioStreamPlayer3D` positional audio |
| `godot-autoload-architecture` | Adding new autoloads, signal buses, or cross-scene singletons |
| `godot-camera-systems` | Modifying `Camera3D`, `SpringArm3D`, camera follow, or shake |
| `godot-combat-system` | Working on hitbox/hurtbox architecture, damage data, or combat flow |
| `godot-composition` | Designing new entity systems or refactoring component boundaries |
| `godot-export-builds` | Preparing export presets, CI/CD pipelines, or platform build settings |
| `godot-gdscript-mastery` | Code review, refactoring for style, or adding static types |
| `godot-genre-action-rpg` | Working on stats, combat, itemization, loot, or progression |
| `godot-genre-card-game` | Implementing card crafting, deck management, or card UI |
| `godot-genre-metroidvania` | Working on map traversal, unlock gates, or exploration logic — design guidance is 2D-framed, so take the structure and not the APIs |
| `godot-genre-platformer` | Working on movement polish, coyote time, or jump buffering — written for 2D precision platformers; the feel principles carry to 3D, the code does not |
| `godot-input-handling` | Modifying input actions, controller support, or rebinding |
| `godot-inventory-system` | Working on inventory, equipment slots, or item drag-drop UI |
| `godot-mcp-scene-builder` | Building scenes programmatically using MCP tools |
| `godot-mcp-setup` | Setting up or troubleshooting the Godot MCP server |
| `godot-multiplayer-networking` | Touching `MultiplayerSynchronizer`, RPC calls, or peer connection logic |
| `godot-navigation-pathfinding` | Modifying NPC navigation, `NavigationAgent3D`, or navmesh baking |
| `godot-particles` | Adding `GPUParticles3D`, VFX, or particle effects to gameplay |
| `godot-performance-optimization` | Diagnosing frame drops, memory issues, or draw call spikes |
| `godot-platform-desktop` | Windows/Linux export settings, window management, or Steam integration |
| `godot-procedural-generation` | Working on procedural level layout, terrain, or dungeon generation |
| `godot-raycasting-queries` | Using `RayCast3D`, shape casts, `DirectSpaceState` queries, mouse picking, or ground probes |
| `godot-resource-data-patterns` | Designing or refactoring `Resource`-based data structures |
| `godot-rpg-stats` | Working on stat sheets, modifiers, derived stats, or leveling |
| `godot-save-load-systems` | Implementing save/load, progress persistence, or data migration |
| `godot-shaders-basics` | Writing or modifying shaders for visual effects or art style |
| `godot-signal-architecture` | Adding new signals, event buses, or decoupling node dependencies |
| `godot-state-machine-advanced` | Modifying player or NPC state machines, sub-states, or transitions |
| `godot-testing-patterns` | Writing GUT tests, async tests, or signal watchers |
| `godot-tweening` | Adding `Tween` animations, UI transitions, or procedural movement |
| `godot-ui-containers` | Building or modifying UI container layouts, grids, or scroll views |
| `godot-ui-theming` | Styling UI with `Theme` resources, `StyleBox`, or font overrides |
| `hiro-framework` | Working with Hiro economy, inventory, energy, progression, or Go hooks |
| `nakama-server-modules` | Writing or modifying Nakama JavaScript modules, RPCs, auth hooks, storage, or wallet |
| `nakama-multiplayer` | Implementing authoritative match handlers, party management, or matchmaker tickets |

## Agent skills

### Issue tracker

Issues are tracked in GitHub Issues (`snackpackgames/cosmicparade`) via the `gh` CLI. External PRs are not a triage surface. See `documentation/agents/issue-tracker.md`.

### Triage labels

Uses the canonical label names as-is (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`). Only `wontfix` exists so far — see `documentation/agents/triage-labels.md` and `CONTRIBUTING.md → Repo setup`.

### AFK implementation pipeline

Loose idea → `/wayfinder-chart` (map with a declared destination type) → `/wayfinder <map>` (one decision per session) → `/wayfinder-handoff <map>` (plan merged to `main`, then labelled issues) → a scheduled cloud routine implements them. See `documentation/agents/afk-pipeline.md`; the routine's prompt is version-controlled at `documentation/agents/scheduled-routine-prompt.md` and must be pasted into `/schedule` by hand after any change.

`wayfinder` itself is vendored from `mattpocock/skills` — never edit `.claude/skills/wayfinder/`. The two pipeline skills (`wayfinder-chart`, `wayfinder-handoff`) and `groom-backlog` are project-owned and live only in `.claude/skills/`, not `.agents/skills/`.

### Domain docs

Single-context: `CONTEXT.md` at the repo root (not yet created — the `/domain-modeling` skill creates it lazily), ADRs in `documentation/adr/`. See `documentation/agents/domain.md`.

### Asking design questions (`/grilling`, wayfinder tickets, `/to-issues` quizzes)

Ask each decision with the `AskUserQuestion` tool, one question per call, not as plain chat text, so the user gets a button picker instead of typing "A". Put the recommended option first with "(Recommended)" at the end of its label, and give each option a one-line description of its trade-off. Keep the facts you looked up (file paths, prior decisions) in the message text before the call; the picker holds only the question and its options. Fall back to a plain-text question only when the answer can't be expressed as 2–4 options, and say so.

## Contributing

See `CONTRIBUTING.md` for branching, PR, and commit conventions.

**When opening a PR, always apply the full metadata** (labels, assignee, milestone, project + Status) listed in `CONTRIBUTING.md → Pull Requests → PR metadata`. Don't wait to be asked.
