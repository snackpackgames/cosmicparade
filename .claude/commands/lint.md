Run gdlint on all GDScript files in the project.

Usage: /lint
- No arguments: lints all `.gd` files (excluding addons, .godot, worktrees)

Steps:
1. Run: `bash scripts/lint.sh`
2. Report the results — number of files linted and any violations found.
3. If violations are found, list each file and the specific issues so they can be fixed.
