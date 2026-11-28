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

## Every debug-only affordance, and the key it answers to. All eight sat on the function row until
## they were moved: six were raw keycodes on F5 to F9 and F12, and F5 to F8 are the Godot editor's
## Play, Play Scene, Pause and Stop, so with the realm scene launched from the editor -- its
## documented route -- F8 stopped the running scene rather than lifting a stool. They are all
## actions now so this table covers them; being raw keycodes is exactly why nothing caught the
## collision.
## https://github.com/snackpackgames/cosmicparade/issues/85
const EXPECTED_DEBUG_ACTIONS := {
	"debug_begin_wing_swell": KEY_1,
	"debug_lift_wing": KEY_2,
	"debug_cycle_wing_figure": KEY_3,
	"debug_lift_furniture": KEY_4,
	"debug_take_ring": KEY_5,
	"debug_lift_shrine": KEY_6,
	"debug_grant_adherents": KEY_7,
	"debug_empty_vessel": KEY_8,
}

## The whole function row is off limits to a debug affordance, so a future remap cannot walk back
## onto it. F5 to F8 are the editor's Play, Play Scene, Pause Scene and Stop; the rest is claimed
## by window managers and browsers often enough that none of it is worth the trouble.
const FUNCTION_KEYS := [
	KEY_F1, KEY_F2, KEY_F3, KEY_F4, KEY_F5, KEY_F6,
	KEY_F7, KEY_F8, KEY_F9, KEY_F10, KEY_F11, KEY_F12,
]

const EXPECTED_REALM_ACTIONS := [
	"realm_lift_or_place", "realm_cancel", "realm_rotate",
	"realm_target_left", "realm_target_right", "realm_target_forward", "realm_target_back",
]


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


func test_the_carry_verb_is_input_map_actions_not_mouse_events() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/54 -- one abstraction,
	# so mouse and gamepad are the same path.
	for action: String in EXPECTED_REALM_ACTIONS:
		assert_true(
			ProjectSettings.has_setting("input/%s" % action), "%s should be bound" % action
		)
		var has_joypad := false
		for event in ProjectSettings.get_setting("input/%s" % action)["events"]:
			has_joypad = has_joypad or event is InputEventJoypadButton \
				or event is InputEventJoypadMotion
		assert_true(has_joypad, "%s should be bound for gamepad" % action)


func test_every_debug_affordance_is_a_declared_action_on_its_key() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/76 named
	# `debug_grant_adherents` as an InputMap action rather than a raw keycode, so
	# project.godot has to carry all of them. No gamepad binding: these stand in for
	# systems that do not exist, not for the carry verb.
	for action: String in EXPECTED_DEBUG_ACTIONS:
		var keycode: Key = EXPECTED_DEBUG_ACTIONS[action]
		assert_true(
			ProjectSettings.has_setting("input/%s" % action), "%s should be declared" % action
		)
		var event := InputEventKey.new()
		event.physical_keycode = keycode
		event.pressed = true
		assert_true(
			InputMap.event_is_action(event, action),
			"%s should answer to %s" % [action, OS.get_keycode_string(keycode)]
		)


func test_no_debug_affordance_sits_on_a_function_key() -> void:
	# The regression this pins: F8 is the editor's Stop, so pressing it in a scene launched from
	# the editor closed the game instead of lifting a stool. A unit test cannot press a key in the
	# editor or in a window manager, but it can refuse the whole row outright.
	for keycode: Key in FUNCTION_KEYS:
		var event := InputEventKey.new()
		event.physical_keycode = keycode
		event.pressed = true
		for action: String in EXPECTED_DEBUG_ACTIONS:
			assert_false(
				InputMap.event_is_action(event, action),
				"%s must not answer to %s: the function row belongs to the editor and the desktop" % [
					action, OS.get_keycode_string(keycode)
				]
			)
