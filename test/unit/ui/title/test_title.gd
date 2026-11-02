extends GutTest
## Smoke test for the project's main scene.

const TITLE_SCENE := preload("res://ui/title/title.tscn")


func test_main_scene_instantiates() -> void:
	var title: Title = add_child_autofree(TITLE_SCENE.instantiate())
	assert_not_null(title, "the main scene should instantiate")


func test_ready_composes_the_environment_line() -> void:
	var title: Title = add_child_autofree(TITLE_SCENE.instantiate())
	var environment_line: Label = title.get_node("%EnvironmentLine")
	# Asserts that the line was composed, never what it says. CI runs --headless
	# with the dummy rendering driver, so the rendering method and viewport size
	# reported there are not what a contributor sees at F5. The configured values
	# are pinned in test_project_settings.gd instead.
	assert_false(
		environment_line.text.is_empty(), "_ready() should compose the environment line"
	)
