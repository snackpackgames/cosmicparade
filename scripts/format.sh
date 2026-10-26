#!/usr/bin/env bash
# Run gdformat on all GDScript files in the project (excluding addons and worktrees).
# Pass --check to validate without writing (used in CI dry-run).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

if ! command -v gdformat &>/dev/null; then
  echo "gdformat not found. Install with: pip install gdtoolkit==4.*"
  exit 1
fi

CHECK_ONLY=0
if [[ "${1:-}" == "--check" ]]; then
  CHECK_ONLY=1
fi

mapfile -t GD_FILES < <(
  find . -name "*.gd" \
    -not -path "./.git/*" \
    -not -path "./.godot/*" \
    -not -path "./addons/*" \
    -not -path "./.worktrees/*" \
    -not -path "./.claude/*"
)

if [[ ${#GD_FILES[@]} -eq 0 ]]; then
  echo "No .gd files found."
  exit 0
fi

if [[ $CHECK_ONLY -eq 1 ]]; then
  echo "Checking format on ${#GD_FILES[@]} GDScript files..."
  gdformat --check "${GD_FILES[@]}"
  echo "Format check passed."
else
  echo "Formatting ${#GD_FILES[@]} GDScript files..."
  gdformat "${GD_FILES[@]}"
  echo "Done."
fi
