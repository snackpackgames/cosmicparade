#!/usr/bin/env bash
# Install local git hooks for this project.
# Safe to run multiple times — skips hooks that are already current.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOKS_DIR="$PROJECT_ROOT/.git/hooks"

if [[ ! -d "$HOOKS_DIR" ]]; then
  echo "error: .git/hooks not found — run this from inside the repo" >&2
  exit 1
fi

install_hook() {
  local name="$1"
  local dest="$HOOKS_DIR/$name"

  if [[ -f "$dest" ]]; then
    if grep -q "scripts/lint.sh" "$dest" 2>/dev/null \
        && ! grep -q "^[[:space:]]*bash .*scripts/test.sh" "$dest" 2>/dev/null; then
      echo "  $name: already installed, skipping"
      return
    fi
    echo "  $name: upgrading hook"
  fi

  cat > "$dest" <<'HOOK'
#!/usr/bin/env bash
# Pre-push hook: run gdlint before every push.
#
# GUT tests are intentionally excluded — a full Godot test suite can exceed
# GitHub's SSH keepalive and kill the connection before git completes the
# push. Run tests manually with scripts/test.sh.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Drain stdin so git doesn't block.
cat > /dev/null

echo "[pre-push] Running gdlint..."
bash "$PROJECT_ROOT/scripts/lint.sh"
HOOK

  chmod +x "$dest"
  echo "  $name: installed"
}

echo "Installing git hooks..."
install_hook "pre-push"
echo "Done. gdlint will run automatically before every git push."
