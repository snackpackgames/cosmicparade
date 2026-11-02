# Vendoring GUT for Godot 4.7

Research asset for [Research: vendoring GUT for Godot
4.7](https://github.com/snackpackgames/cosmicparade/issues/6), a ticket on [Map:
bootstrap the Godot project](https://github.com/snackpackgames/cosmicparade/issues/2).

Compiled 2026-10-28 against GUT **v9.7.1** (the tag's own source and docs) and this
repo's existing CI and scripts.

**Headline: the pin holds.** GUT v9.7.1 targets Godot 4.7.x, so the `4.7.2-stable`
decision in [Which Godot version the project
pins](https://github.com/snackpackgames/cosmicparade/issues/13) does not need
revisiting. This ticket carried that risk and it did not materialise.

## 1. Which release, and the trap in getting it

GUT's own compatibility table:

| GUT | Godot | Where |
|---|---|---|
| **v9.7.1** | **4.7.x** | tag `v9.7.1`, branch `godot_4_7` |
| Main branch | 4.6.x | `main` |
| v9.6.1 | 4.6.x | tag `v9.6.1`, **and the Asset Library** |
| v9.5.0 | 4.5.x | tag |
| v9.4.0 | 4.3.x–4.4.x | tag |

v9.7.1 was published 2026-07-10. v9.7.0 (2026-06-19) landed the day after Godot 4.7
stable and its feature list is literally "Compatibility changes for Godot 4.7".

**The trap: the two most obvious acquisition routes both give you the 4.6 version.**

- GUT's `main` branch is the **4.6.x** line, not the development line for 4.7. Cloning
  the default branch gets the wrong engine target.
- The **Asset Library carries v9.6.1 only**, which is 4.6.x. There is no 4.7 entry. So
  "install from AssetLib", which is the first install method GUT's own docs list,
  cannot deliver what this project needs.

The 4.7 line must come from the tag `v9.7.1` or the `godot_4_7` branch, explicitly.

## 2. `gut_cmdln.gd` is still the CLI entry point

Confirmed present at `addons/gut/gut_cmdln.gd` in the v9.7.1 tree (2,594 bytes). It is
a thin `SceneTree` script whose own header says the real logic lives in
`addons/gut/cli/gut_cli.gd`. So the path hardcoded in `scripts/test.sh` and in
`.github/workflows/godot-ci.yml` — `res://addons/gut/gut_cmdln.gd` — is correct for
v9.7.1 and needs no change.

GUT's docs give the base invocation as
`godot -d -s --path "$PWD" addons/gut/gut_cmdln.gd`, and document `-gdir`, `-gtest`,
`-ginclude_subdirs`, `-gexit` and `-gconfig` as this repo's scripts already use them.
Exit code is 0 when all tests pass and 1 when any fail; pending tests do not affect it.

## 3. The import step is mandatory, and skipping it fails *silently green*

This is the most important operational finding.

`gut_cmdln.gd` opens by calling
`VersionConversion.error_if_not_all_classes_imported()`. That function checks whether
GUT's own `class_name` declarations are in the global script class cache, and if any
are missing it does this:

```gdscript
push_error(str("Some GUT class_names have not been imported.  Please restart the Editor or run godot --headless --import\n",
    "Missing class_names:  ", missing_class_names))
return true
```

and `gut_cmdln.gd` then calls **`quit(0)`**.

Exit code **zero**, with **no tests run**. `push_error` does not fail a headless run, so
CI would report a green test job having executed nothing at all.

**This repo is already safe**: `.github/workflows/godot-ci.yml` has a dedicated
`Import assets` step running `godot --headless --import` before the GUT step, and
`scripts/import.sh` does the same locally. The finding is that **this step is
load-bearing, not hygiene** — removing it, or reordering it after the test step, buys a
permanently green CI that tests nothing. It is worth a comment in the workflow saying
so.

This also answers the map's open fog about whether CI needs an import/class-cache gate:
it already has one, and it must keep it.

### A second route to the same silent pass

`docs/compile-design-document` (unmerged, [#1](https://github.com/snackpackgames/cosmicparade/pull/1))
adds a probe step to `godot-ci.yml` that skips the whole test job when either
`project.godot` or **`addons/gut/gut_cmdln.gd`** is missing, by design, so a
scaffold-only repo reports green rather than red. That is the right call for the
current window, and it corroborates §5 — CI expects the vendored addon to be present in
the checkout, by path.

It does mean there are now **two** ways to get a green test job that ran nothing: no
vendored GUT (skipped by the probe) and an un-imported class cache (`quit(0)` inside
GUT). The first is intentional and announces itself in the step summary. The second is
silent. Once `addons/gut/` lands, the probe stops firing and the import step becomes the
only thing standing between CI and a meaningless pass.

## 4. Our `.gutconfig.json` is entirely valid

All four keys this repo uses are real options in v9.7.1, verified in
`addons/gut/gut_config.gd`'s `default_options` dictionary:

| Our key | Status |
|---|---|
| `dirs` | valid (documented) |
| `include_subdirs` | valid (documented) |
| `should_exit` | valid (documented) |
| `pre_run_script` | **valid in source** — `default_options.pre_run_script` is declared and applied to the GUT instance |

`pre_run_script` is worth calling out: it is **absent from the sample config in GUT's
Command-Line docs**, which lists only `dirs`, `double_strategy`, `ignore_pause`,
`include_subdirs`, `inner_class`, `log_level`, `opacity`, `prefix`, `selected`,
`should_exit`, `should_maximize`, `suffix`, `tests` and `unit_test_name`. Reading the
docs alone would suggest this repo's `pre_run_script` key is ignored. It is not — the
source declares it, and the CLI equivalent `-gpre_run_script` is documented. GUT 9.7.0
also added documentation for setting global per-test hooks in the pre-run hook, so the
mechanism is actively supported.

`-gjunit_xml_file`, which CI passes, likewise maps to a real `junit_xml_file` option.

So `test/hooks/pre_run_hook.gd` — the hook that catches unloadable test scripts GUT
would otherwise silently drop, per `CLAUDE.md → Running and Testing` — will attach as
described.

## 5. Acquisition: a committed vendored copy, effectively forced

Three routes were considered. Two are ruled out by facts rather than taste:

- **Asset Library — impossible.** It only has v9.6.1 (4.6.x). See §1.
- **Git submodule — not recommended by GUT and awkward in CI.** GUT's install docs
  explicitly do not recommend using the repository as a submodule, suggesting a clone
  plus a symlink of `addons/gut` for development instead — which does not survive a CI
  checkout. A submodule would also require `submodules: true` on
  `actions/checkout@v7`, which the workflow does not currently pass.
- **Committed vendored copy — works as the repo already stands.** CI checks out the
  repo and installs no addons, so `addons/gut/` must simply be present. This is also
  exactly GUT's documented manual install: download the tag zip, place the `gut` folder
  in `addons/`.

Supporting details:

- GUT ships its own `.uid` sidecars (e.g. `gut_cmdln.gd.uid`), which
  `CLAUDE.md → Common Gotchas` requires be committed regardless.
- `addons/gut/plugin.cfg` carries `version="9.7.1"`, so a vendored copy
  **self-documents which release was taken** — no separate version file is needed to
  know what to upgrade from.
- There are **no release assets** attached to the GUT releases, so the source is the
  tag archive (`.../archive/refs/tags/v9.7.1.zip`) or a git checkout of the tag.

## 6. No conflict with this repo's existing tooling

Checked, because vendoring a third-party addon into a linted repo is where this usually
goes wrong:

- `scripts/lint.sh` already excludes `./addons/*` from its `find`, so gdlint will not
  lint GUT's source. CI's lint job runs that same script.
- `.gitignore` does **not** exclude `addons/`, so a vendored copy commits cleanly.
- `.gdlintrc` already carries `ignored-classes: ["GutTest"]`.

The configuration ported from `fiber` clearly anticipated a vendored GUT. Nothing needs
changing to accommodate it.

## 7. Plugin enablement: editor-only, on the evidence

GUT's docs say to activate the plugin in Project Settings → Plugins, and tie that
explicitly to the **GUT Panel appearing** in the editor. Neither the install page nor
the command-line page says the plugin must be enabled for CLI runs.

The source agrees: `gut_cmdln.gd` is a plain `SceneTree` script that loads
`addons/gut/gut_loader.gd` and `addons/gut/cli/gut_cli.gd` by path. What it actually
depends on is the **global class cache** (§3), not the `EditorPlugin`;
`addons/gut/gut_plugin.gd` and `plugin.cfg` exist to provide the editor panel.

**Recommendation: enable it in `project.godot` anyway.** It is one line in
`[editor_plugins]`, costs nothing headless, and contributors opening the project want
the panel. The residual uncertainty — whether a disabled plugin would break CLI runs —
is settled for free by the first CI run either way.

## 8. One thing for whoever writes the first tests

Not a scaffold decision, but it will bite the first person to use doubles. GUT 9.7.0
carries a **breaking change driven by Godot 4.7**:

> Godot 4.7 introduced more restrictive type checking for return values. In prior
> releases Doubles could return `null` regardless of the declared return type. Doubles
> have been adjusted to return a default value for each `TYPE_` constant.

So a double of a method declared `-> int` now returns `0`, not `null`, and stubbing a
method to return a type-invalid value produces a `[GUT ERROR]` plus an engine error
while execution continues. `stub(...).to_do_nothing()` now returns the declared type's
default. Tests written against pre-9.7 null-returning doubles can produce false
positives and false negatives. Default values per `TYPE_` constant are listed in GUT's
Doubles documentation.

## Sources

- [GUT releases](https://github.com/bitwes/Gut/releases) — v9.7.1, 2026-07-10
- [GUT README @ v9.7.1](https://github.com/bitwes/Gut/blob/v9.7.1/README.md) — the
  GUT-version/Godot-version table
- [v9.7.0 release notes](https://github.com/bitwes/Gut/releases/tag/v9.7.0) — "Compatibility
  changes for Godot 4.7" and the Doubles breaking change
- `addons/gut/gut_cmdln.gd`, `addons/gut/gut_config.gd`,
  `addons/gut/version_conversion.gd`, `addons/gut/plugin.cfg` @ `v9.7.1`
- [Command Line (v9.7.1)](https://gut.readthedocs.io/en/v9.7.1/Command-Line.html)
- [Install (v9.7.1)](https://gut.readthedocs.io/en/v9.7.1/Install.html)
- This repo: `.github/workflows/godot-ci.yml`, `scripts/test.sh`, `scripts/import.sh`,
  `scripts/lint.sh`, `.gutconfig.json`, `.gdlintrc`
