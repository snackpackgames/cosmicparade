## Added to the run by pre_run_hook.gd only when GUT dropped test scripts it
## could not load. Lives outside test/unit/ so normal collection never picks it up.
extends GutTest


func test_all_test_scripts_load() -> void:
	var paths: PackedStringArray = gut.get_pre_run_script_instance().unloadable_script_paths
	for path in paths:
		fail_test(
			(
				"%s could not be loaded, so none of its tests ran. Check the log above for "
				+ "its Parse Error (in the script or something it preloads)."
			)
			% path
		)
