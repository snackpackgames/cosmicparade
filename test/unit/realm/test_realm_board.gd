extends GutTest
## The realm board: one hex space per coordinate it was given.

const REALM_SCENE := preload("res://realm/realm.tscn")
const HEXES: Array[Vector2i] = [Vector2i.ZERO, Vector2i(1, 0), Vector2i(0, 1)]
# HEXES with the one hex a Swell brings. Spelt out because adding two typed arrays
# yields an untyped one, which set_hexes refuses.
const GROWN: Array[Vector2i] = [Vector2i.ZERO, Vector2i(1, 0), Vector2i(0, 1), Vector2i(5, 0)]


func _board(zones: Array[InfluenceZone]) -> RealmBoard:
	var board: RealmBoard = add_child_autofree(RealmBoard.new())
	board.zones = zones
	board.build(HEXES)
	return board


func test_it_builds_one_hex_space_per_coordinate_it_was_given() -> void:
	var board := _board([] as Array[InfluenceZone])
	for hex: Vector2i in HEXES:
		assert_not_null(board.hex_space(hex), "no space built for %s" % hex)


func test_a_fresh_realm_is_flat() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/27
	var board := _board([] as Array[InfluenceZone])
	for hex: Vector2i in HEXES:
		assert_almost_eq(board.hex_space(hex).top_height(), 0.0, 0.0001)


func test_it_raises_a_hex_two_same_domain_zones_cover() -> void:
	var zones: Array[InfluenceZone] = [
		InfluenceZone.new(Domain.Kind.STONE, [Vector2i.ZERO, Vector2i(1, 0)]),
		InfluenceZone.new(Domain.Kind.STONE, [Vector2i.ZERO]),
	]
	var board := _board(zones)
	assert_almost_eq(
		board.hex_space(Vector2i.ZERO).top_height(), Elevation.height_for_depth(1), 0.0001
	)
	assert_almost_eq(board.hex_space(Vector2i(1, 0)).top_height(), 0.0, 0.0001)


func test_removing_a_zone_lowers_the_ground_it_raised() -> void:
	# Height always equals current depth; there is no high-water mark.
	# https://github.com/snackpackgames/cosmicparade/issues/38
	var zones: Array[InfluenceZone] = [
		InfluenceZone.new(Domain.Kind.FOREST, [Vector2i.ZERO]),
		InfluenceZone.new(Domain.Kind.FOREST, [Vector2i.ZERO]),
	]
	var board := _board(zones)
	assert_gt(board.hex_space(Vector2i.ZERO).top_height(), 0.0)
	board.zones = [zones[0]] as Array[InfluenceZone]
	board.rebuild([Vector2i.ZERO] as Array[Vector2i])
	assert_almost_eq(board.hex_space(Vector2i.ZERO).top_height(), 0.0, 0.0001)


func test_rebuild_touches_only_the_hexes_it_was_given() -> void:
	var board := _board([] as Array[InfluenceZone])
	board.zones = [
		InfluenceZone.new(Domain.Kind.GALE, [Vector2i.ZERO, Vector2i(1, 0)]),
		InfluenceZone.new(Domain.Kind.GALE, [Vector2i.ZERO, Vector2i(1, 0)]),
	] as Array[InfluenceZone]
	board.rebuild([Vector2i.ZERO] as Array[Vector2i])
	assert_gt(board.hex_space(Vector2i.ZERO).top_height(), 0.0, "the named hex rebuilt")
	assert_almost_eq(
		board.hex_space(Vector2i(1, 0)).top_height(), 0.0, 0.0001,
		"an unnamed hex must be left alone even when its coverage changed"
	)


# Review Focus 3: zone edges and Swell will name hexes off the board.
func test_rebuilding_a_hex_the_board_does_not_hold_is_a_no_op() -> void:
	var board := _board([] as Array[InfluenceZone])
	board.rebuild([Vector2i(99, -99)] as Array[Vector2i])
	assert_null(board.hex_space(Vector2i(99, -99)))
	assert_eq(board.get_child_count(), HEXES.size())


func test_set_hexes_adds_the_spaces_a_swell_brings() -> void:
	var board := _board([] as Array[InfluenceZone])
	board.set_hexes(GROWN)
	assert_not_null(board.hex_space(Vector2i(5, 0)))
	assert_eq(board.get_child_count(), 4)


func test_set_hexes_frees_the_spaces_a_lifted_wing_takes_away() -> void:
	var board := _board([] as Array[InfluenceZone])
	board.set_hexes([Vector2i.ZERO] as Array[Vector2i])
	await wait_frames(1)
	assert_null(board.hex_space(Vector2i(1, 0)))
	assert_eq(board.get_child_count(), 1)


func test_set_hexes_leaves_an_unchanged_space_alone() -> void:
	var board := _board([] as Array[InfluenceZone])
	var space := board.hex_space(Vector2i.ZERO)
	board.set_hexes(GROWN)
	assert_eq(board.hex_space(Vector2i.ZERO), space, "the same node, not a rebuilt one")


func test_a_new_space_takes_the_depth_the_zones_already_give_it() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/59 — a Swell can raise
	# ground on the new land with nothing newly placed.
	var board := _board([
		InfluenceZone.new(Domain.Kind.FOREST, [Vector2i(5, 0)]),
		InfluenceZone.new(Domain.Kind.FOREST, [Vector2i(5, 0)]),
	] as Array[InfluenceZone])
	board.set_hexes(GROWN)
	assert_almost_eq(
		board.hex_space(Vector2i(5, 0)).top_height(), Elevation.height_for_depth(1), 0.0001
	)


func test_the_realm_scene_builds_a_radius_three_board() -> void:
	var realm: Node3D = add_child_autofree(REALM_SCENE.instantiate())
	await wait_frames(1)
	assert_eq(realm.get_node("RealmBoard").get_child_count(), 37)


func test_the_realm_scene_instantiates_with_a_board() -> void:
	var realm: Node3D = add_child_autofree(REALM_SCENE.instantiate())
	assert_not_null(realm.get_node_or_null("RealmBoard"), "the scene should hold a RealmBoard")


func test_the_realm_scene_is_not_the_main_scene() -> void:
	assert_eq(
		ProjectSettings.get_setting("application/run/main_scene"), "res://ui/title/title.tscn"
	)
