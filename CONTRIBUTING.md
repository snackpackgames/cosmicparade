# Contributing to Cosmic Parade

This document covers conventions for contributors — human and AI alike.

## Branches

Human contributors may use either format below. **AI agents must always use a topic-prefixed branch** (never a personal branch, and never an auto-generated codename branch like `claude/charming-faraday-37tkyg`).

- `<username>/<short-description>` — personal branches, humans only: `broberto/item-detail-ui`
- `<prefix>/<short-description>` — topic-prefixed branches, required for agents, available to anyone. One of:
  - `feature/` — new feature or system work: `feature/emblem-system`
  - `fix/` — bug fixes, including hotfixes: `fix/empty-tags-upgrade`
  - `docs/` — documentation-only changes: `docs/entity-lifecycle-design`
  - `research/` — exploratory work, spikes, prototypes: `research/save-system-design`

If the work is tied to a specific GitHub issue, fuse the issue number into the slug: `fix/574-affix-instance-dedup`. Omit it when there is no tracked issue.

**Slug rules:**
- kebab-case only — no underscores, no `#`
- 5 words max
- must not be a single generic word with no descriptive content: `misc`, `updates`, `improvements`, `fixes`, `changes`, `stuff`, `various`, `cleanup`

- Branch from `main`
- One branch per issue or closely related set of changes
- Keep branches short-lived; open a PR as soon as there is something to review

## Pull Requests

- Title should match the primary change in imperative mood: `Add hitbox system`, `Fix player falling state`
- Reference the issue in the PR body: `Closes #32`
- Keep PRs focused — avoid bundling unrelated fixes
- All CI checks (lint + GUT tests) must pass before merging

### PR metadata

Every PR gets the following metadata when it is opened. AI agents must apply all of it without being asked.

| Field | Rule |
|-------|------|
| **Labels** | Exactly one type label: `enhancement`, `bug`, `documentation`, `tools`, `research`, or `test`. Add one or more area labels for the systems touched |
| **Assignee** | The PR author (for agent-opened PRs, the human driving the session) |
| **Milestone** | The linked issue's milestone. If the issue has none and is a Wayfinder ticket, use its parent map's milestone. If neither has one, choose the milestone whose description covers the system changed |
| **Project** | `Cosmic Parade v1.0`, with **Status** set to `In Progress` |

> **Setup still pending.** This repo currently has only GitHub's default labels, no milestones, and no project board. Until the `Cosmic Parade v1.0` board and the label/milestone set exist, apply whatever subset is available and say which fields were skipped. See [Repo setup](#repo-setup-still-pending).

Apply it with `gh` (`gh pr create` accepts the same `--label` / `--assignee` / `--milestone` flags):

```bash
gh pr edit <number> \
  --add-label "enhancement,combat" \
  --add-assignee @me \
  --milestone "<milestone title>"

# Fallback only, if the PR isn't on the board yet
gh pr edit <number> --add-project "Cosmic Parade v1.0"

# Set the project Status field (gh pr edit cannot set project fields).
# Resolve the ids fresh — they are not stable across repos:
#   gh project list --owner snackpackgames --format json
#   gh project field-list <project_number> --owner snackpackgames --format json
item_id=$(gh project item-list <project_number> --owner snackpackgames --format json --limit 2000 \
  --jq '.items[] | select(.content.type == "PullRequest" and .content.number == <number>) | .id')
gh project item-edit --project-id <PROJECT_ID> --id "$item_id" \
  --field-id <STATUS_FIELD_ID> --single-select-option-id <IN_PROGRESS_OPTION_ID>
```

If a board's built-in auto-add workflow is enabled, it usually adds new PRs on its own with Status `Backlog`, so the step that is always needed is setting Status. Adding the PR to the project yourself is only a fallback: if it fails with `Content already exists in this project`, auto-add already did it.

To find the source milestone: `gh issue view <issue> --json milestone,labels,projectItems`. The `gh project` commands need the `project` token scope; if they fail, run `gh auth refresh -s project`.

**In a Claude Code cloud session**, `gh pr edit`, `gh issue view` and `gh project` fail because the session can't use GitHub's GraphQL API. Apply labels, assignee and milestone through `gh api` REST calls instead, and leave the project board and Status to the human. See [Cloud sessions in the issue-tracker doc](documentation/agents/issue-tracker.md#cloud-sessions-claude-code-on-the-web).

## Commit Messages

Conventional commit prefixes are encouraged but not enforced:

| Prefix | When to use |
|--------|-------------|
| `feat:` | New feature or system |
| `fix:` | Bug fix |
| `docs:` | Documentation only |
| `style:` | Formatting, naming, or whitespace — no behavior change |
| `test:` | Adding or updating tests |
| `refactor:` | Code restructure with no behavior change |
| `chore:` | Tooling, config, dependency updates |
| `repo:` | CI/CD, GitHub Actions, AI agent config, or project infrastructure |

When a commit message needs a body, use bullet points — not paragraphs:

```
feat: add hurtbox knockback response

- Apply knockback force based on attack_data direction and strength
- Respect resistance_profile knockback reduction
- Skip knockback for entities flagged as immovable
```

Single-line commits are fine when the change is self-explanatory.

## Code Conventions

Follow the patterns in `CLAUDE.md`. Short version:

- `class_name` declarations on all reusable scripts
- `@export` for editor-tunable properties, `@onready` for node references
- `%UniqueName` syntax for unique node access
- `.tscn` files paired with `.gd` in the same directory
- Data in `.tres` Resources; logic in scripts
- `.uid` and `.import` sidecar files are **not** gitignored — commit them alongside new scripts and assets. A missing `.import` makes every clone and CI re-import that model or texture with default settings

## Local environment (`.env`)

The project uses a `.env` file (gitignored) for machine-specific configuration. Copy
`.env.example` to `.env` and fill in the values. The bash scripts in `scripts/` read this
file automatically.

| Variable | Default | Purpose |
|----------|---------|---------|
| `GODOT` | *(required)* | Path to Godot 4.6+ executable |

Example `.env`:

```
GODOT="/path/to/Godot_v4.6.1-stable_linux.x86_64"
```

In a disposable sandbox with no interactive user (e.g. a cloud agent run), run
`bash scripts/ensure-godot.sh` instead — it downloads the pinned Godot version into a
cache directory and writes `.env` itself.

## Linting and Formatting

GDScript files are linted with `gdlint` and formatted with `gdformat`, both from the [gdtoolkit](https://github.com/Scony/godot-gdscript-toolkit) package. CI runs `gdlint` on every PR — failing lint blocks merge.

### Install Python

gdtoolkit requires Python 3.9+. If you don't have Python installed:

- **Windows:** Download from [python.org](https://www.python.org/downloads/). During installation, check **"Add Python to PATH"** — this is unchecked by default and required for `gdlint`/`gdformat` to be found from the terminal.
- **macOS:** `brew install python` (via [Homebrew](https://brew.sh)), or download from [python.org](https://www.python.org/downloads/).
- **Linux:** `sudo apt install python3 python3-pip` (Debian/Ubuntu) or your distro's equivalent.

Verify Python is on your PATH after installation:

```bash
python --version   # should print 3.9 or higher
```

### Install gdtoolkit

```bash
pip install "gdtoolkit==4.*"
```

Verify the tools are available:

```bash
gdlint --version
gdformat --version
```

> **Windows note:** If `gdlint` is not found after `pip install`, the Scripts directory may not be on your PATH. This happens when Python was installed from the Microsoft Store (which puts scripts in a non-standard location). The fix is to reinstall Python from [python.org](https://www.python.org/downloads/) with **"Add Python to PATH"** checked.

### Running the linter and formatter

```bash
# Check for lint violations
bash scripts/lint.sh

# Auto-format all GDScript files
bash scripts/format.sh

# Check formatting without writing (dry run)
bash scripts/format.sh --check
```

Run both before pushing. `gdformat` handles indentation, spacing, and line length automatically; `gdlint` catches naming conventions and structural issues that require manual fixes.

### Pre-push hook

Install a git pre-push hook so lint runs automatically before every `git push`, catching violations before they reach CI:

```bash
bash scripts/install-hooks.sh
```

The hook runs `gdlint`, blocks the push, and prints violations if it fails. The GUT suite is intentionally not part of the hook — a full suite takes long enough to drop the push's SSH connection — so run `bash scripts/test.sh` yourself before pushing. Re-run `install-hooks.sh` after pulling hook changes; it upgrades an outdated hook in place. Run the script once per clone — `.git/hooks/` is not tracked, so each contributor needs to run it themselves after cloning.

To verify the hook is installed:

```bash
cat .git/hooks/pre-push
```

To uninstall, delete the file:

```bash
rm .git/hooks/pre-push
```

## Tests

- Tests live in `test/unit/` and mirror the source tree
  - e.g., `combat/hitbox.gd` → `test/unit/combat/test_hitbox.gd`
- Test classes extend `GutTest`
- Run tests locally before pushing: `bash scripts/test.sh` (see `CLAUDE.md` for setup)
- A test script that fails to parse is caught by `test/hooks/pre_run_hook.gd` and reported as a failure of `test_all_test_scripts_load`, rather than being silently dropped by GUT

## Repo setup (still pending)

This repo was scaffolded from the fiber project's configuration. The following still need to be created before every convention above works end to end:

- [ ] The Godot project itself (`project.godot`, `main.tscn`, `icon.svg`)
- [ ] The GUT addon under `addons/gut/` (CI and `scripts/test.sh` both invoke `res://addons/gut/gut_cmdln.gd`)
- [ ] `export_presets.cfg` and release packaging, if desktop builds are wanted
- [ ] Type and area labels beyond GitHub's defaults
- [ ] Milestones
- [ ] The `Cosmic Parade v1.0` GitHub Projects (v2) board with a `Status` single-select field (`Backlog`, `Refining`, `Refined`, `Blocked`, `Todo`, `In Progress`, `Done`) — the `/groom-backlog` skill requires it
- [ ] Triage labels: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human` (`wontfix` already exists) — see `documentation/agents/triage-labels.md`
- [ ] Wayfinder labels: `wayfinder:map`, `wayfinder:research`, `wayfinder:prototype`, `wayfinder:grilling`, `wayfinder:task`
- [ ] The `CLAUDE_CODE_OAUTH_TOKEN` repo secret, for the `@claude` GitHub Actions workflow

## AI Tooling (Claude Code)

Contributors using Claude Code get automatic AI skill coverage for Godot through the project's Claude Code plugins.

### Plugin installation

**Step 1 — Register the snackpackgames marketplace (once per machine):**

In Claude Code:
```
/plugin marketplace add snackpackgames/snackpackgames-claude-plugins
```

**Step 2 — Install both plugins (run from the project root):**

```
/plugin install superpowers@claude-plugins-official
/plugin install snackpackgames-claude-plugins@snackpackgames
```

After installation, all skills appear in the session-start system-reminder. Claude invokes them automatically when you work in relevant areas of the codebase.

If skills are absent from a session, the plugins were likely installed for a different project path (e.g. after a folder rename). Re-running the two install commands fixes it.

### Godot MCP server (optional)

The Godot MCP server lets Claude create and modify `.tscn` scene files directly via `mcp_godot_*` tools, instead of only describing what to do. This is useful for generating new scenes programmatically. The `godot-mcp-setup` skill walks through it: `Skill("godot-mcp-setup")`.

> The MCP server is **optional**. All other skills work without it.

## AI Agent Guidelines

When using Claude Code or other AI agents on this project:

- Read `CLAUDE.md` first — it has architecture context, test commands, and common gotchas
- Check `documentation/` for system-level specs before modifying an existing system
- Check `notes/` for in-progress research and pending GitHub issue content
- Open a PR (or at minimum a branch) rather than committing directly to `main`
- Commit only files explicitly related to the task; do not auto-commit unrelated changes
- When adding a new `class_name` script, note that `--import` must be run before tests will recognize the new class (see `CLAUDE.md` gotchas)
