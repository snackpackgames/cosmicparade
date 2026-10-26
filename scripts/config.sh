#!/bin/bash
# scripts/config.sh — Shared configuration for project scripts
# Sources .env from the project root for GODOT path.
# PROJECT_ROOT is auto-detected (worktree-aware).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SHARED_PROJECT_ROOT="$(cd "$(git rev-parse --git-common-dir)/.." && pwd)"

# Load .env if it exists
if [[ -f "$PROJECT_ROOT/.env" ]]; then
  source "$PROJECT_ROOT/.env"
fi

if [[ -z "$GODOT" ]]; then
  echo "ERROR: GODOT is not set."
  echo "Create a .env file in the project root with:"
  echo "  GODOT=\"/path/to/your/godot/executable\""
  echo "See .env.example for reference."
  exit 1
fi
