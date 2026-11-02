extends GutTest
## Pins every project setting the bootstrap decided.
##
## Lives at the root of test/unit/ rather than in a mirror directory: the mirror
## rule governs tests of source files, and this test's subject is project.godot.
##
## ProjectSettings.get_setting() returns the engine default for a key absent from
## project.godot, so these assertions prove the *effective* configuration rather
## than the contents of the file. That is the right thing to assert, since the
## effective value is what renders -- but it means a pass here is not evidence
## that the key is written down.

const EXPECTED_LAYER_NAMES := {
	1: "realm_space",
	2: "furniture",
	3: "fixture",
	9: "biome_ground",
	10: "terrain_feature",
	17: "entity",
	25: "parade_space",
	26: "tile",
}


func test_main_scene_is_the_title_screen() -> void:
	assert_eq(
		ProjectSettings.get_setting("application/run/main_scene"), "res://ui/title/title.tscn"
	)


func test_renderer_is_forward_plus() -> void:
	assert_eq(
		ProjectSettings.get_setting("rendering/renderer/rendering_method"), "forward_plus"
	)


func test_3d_scaling_is_nearest_at_full_scale() -> void:
	# Named constants, not ordinals: this is what backstops the integers written
	# into project.godot.
	assert_eq(
		ProjectSettings.get_setting("rendering/scaling_3d/mode"),
		Viewport.SCALING_3D_MODE_NEAREST
	)
	assert_eq(ProjectSettings.get_setting("rendering/scaling_3d/scale"), 1.0)


func test_anti_aliasing_is_msaa_4x_only() -> void:
	assert_eq(
		ProjectSettings.get_setting("rendering/anti_aliasing/quality/msaa_3d"), Viewport.MSAA_4X
	)
	assert_eq(ProjectSettings.get_setting("rendering/anti_aliasing/quality/screen_space_aa"), 0)
	assert_false(ProjectSettings.get_setting("rendering/anti_aliasing/quality/use_taa"))


func test_window_is_1080p_with_expanding_canvas_items_stretch() -> void:
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_width"), 1920)
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_height"), 1080)
	assert_eq(ProjectSettings.get_setting("display/window/stretch/mode"), "canvas_items")
	assert_eq(ProjectSettings.get_setting("display/window/stretch/aspect"), "expand")


func test_every_decided_3d_physics_layer_is_named() -> void:
	# Deliberately does not assert the other 24 bits are empty. The layer table
	# invites claiming the next free bit inside a role's block, and doing so must
	# not fail this test.
	for bit: int in EXPECTED_LAYER_NAMES:
		var expected: String = EXPECTED_LAYER_NAMES[bit]
		assert_eq(
			ProjectSettings.get_setting("layer_names/3d_physics/layer_%d" % bit),
			expected,
			"3D physics layer %d should be named %s" % [bit, expected]
		)
