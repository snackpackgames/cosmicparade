#!/usr/bin/env bash
# Run gdlint on all GDScript files in the project (excluding addons and worktrees).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

if command -v gdlint &>/dev/null; then
  GDLINT="gdlint"
elif python -c "import gdtoolkit" &>/dev/null 2>&1; then
  GDLINT="python -m gdtoolkit.linter"
else
  echo "gdlint not found. Install with: pip install gdtoolkit==4.*"
  exit 1
fi

mapfile -t GD_FILES < <(
  find . -name "*.gd" \
    -not -path "./.git/*" \
    -not -path "./.godot/*" \
    -not -path "./addons/*" \
    -not -path "./.worktrees/*" \
    -not -path "./.claude/*" \
    -not -path "*/node_modules/*"
)

if [[ ${#GD_FILES[@]} -eq 0 ]]; then
  echo "No .gd files found."
  exit 0
fi

echo "Linting ${#GD_FILES[@]} GDScript files..."
# Batched: a single invocation with every path overflows the Windows command line.
for ((i = 0; i < ${#GD_FILES[@]}; i += 200)); do
  $GDLINT "${GD_FILES[@]:i:200}"
done
echo "Lint passed."
