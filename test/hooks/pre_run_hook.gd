## GUT pre-run hook (wired up via "pre_run_script" in .gutconfig.json).
##
## When GUT cannot load a test script (a parse error in the script itself or in
## anything it preloads), its collector drops the script with only a warning, so
## none of its tests run and the run still passes. This hook finds those dropped
## scripts in the logger's warnings and adds a report script whose test fails
## once per dropped script, so they show up in the summary, JUnit XML, and exit code.
extends GutHookScript

const REPORT_SCRIPT_PATH := "res://test/hooks/unloadable_test_scripts_report.gd"
# Emitted by addons/gut/test_collector.gd add_script() for any script it drops.
const DROPPED_SCRIPT_PREFIX := "Ignoring script "
const DROPPED_SCRIPT_SUFFIX := " because it does not extend GutTest"

var unloadable_script_paths: PackedStringArray = []


func run() -> void:
	for warning in gut.logger.get_warnings():
		var text := str(warning)
		var start := text.find(DROPPED_SCRIPT_PREFIX)
		var end := text.find(DROPPED_SCRIPT_SUFFIX)
		if start == -1 or end == -1:
			continue
		start += DROPPED_SCRIPT_PREFIX.length()
		unloadable_script_paths.append(text.substr(start, end - start))

	if not unloadable_script_paths.is_empty():
		gut.add_script(REPORT_SCRIPT_PATH)
