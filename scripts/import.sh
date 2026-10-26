#!/bin/bash
# scripts/import.sh — Rebuild Godot global script class cache
# Run after adding any new class_name declaration.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/config.sh"

"$GODOT" --headless --import --path "$PROJECT_ROOT"
