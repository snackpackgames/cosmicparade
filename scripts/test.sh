#!/bin/bash
# scripts/test.sh — Run GUT tests
# Usage:
#   bash scripts/test.sh              # run all tests
#   bash scripts/test.sh combat       # run tests in test/unit/combat/
#   bash scripts/test.sh combat/test_hitbox.gd  # run a single test file

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/config.sh"

if [[ -z "$1" ]]; then
  "$GODOT" -v --headless -s addons/gut/gut_cmdln.gd -gdir=res://test/unit/ -ginclude_subdirs -gexit --path "$PROJECT_ROOT"
elif [[ "$1" == *.gd ]]; then
  # -gtest= only adds the file to whatever -gdir already collected, so -gdir=
  # clears .gutconfig.json's dirs (res://test/unit/) to run just this file.
  # Don't narrow with -gselect instead: it resolves the script list before the
  # pre-run hook runs, so a file that fails to parse would be dropped with exit
  # code 0 instead of being reported as a failure by test/hooks/pre_run_hook.gd.
  "$GODOT" -v --headless -s addons/gut/gut_cmdln.gd -gdir= -gtest="res://test/unit/$1" -gexit --path "$PROJECT_ROOT"
else
  "$GODOT" -v --headless -s addons/gut/gut_cmdln.gd -gdir="res://test/unit/$1/" -ginclude_subdirs -gexit --path "$PROJECT_ROOT"
fi
