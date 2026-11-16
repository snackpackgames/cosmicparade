extends GutTest
## Influence falling off the rock: the zone's coordinates with no hex under them.


func test_a_zone_wholly_on_the_board_spills_nothing() -> void:
	var display: SpillDisplay = add_child_autofree(SpillDisplay.new())
	display.show_spill(
		InfluenceZone.project(Domain.Kind.FOREST, [Vector2i.ZERO] as Array[Vector2i], 1),
		RealmGeometry.new()
	)
	assert_eq(display.spilled_hexes(), [] as Array[Vector2i])


func test_a_rim_placement_spills_the_coordinates_with_no_hex_under_them() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/59 -- 7 from the centre,
	# 5 from a rim hex that is not a corner, so two coordinates fall into the void.
	var display: SpillDisplay = add_child_autofree(SpillDisplay.new())
	display.show_spill(
		InfluenceZone.project(Domain.Kind.FOREST, [Vector2i(3, -1)] as Array[Vector2i], 1),
		RealmGeometry.new()
	)
	assert_eq(display.spilled_hexes().size(), 2)


func test_a_corner_placement_spills_more_than_a_rim_one() -> void:
	# 4 of 7 stay on a radius-3 board from a corner hex.
	var display: SpillDisplay = add_child_autofree(SpillDisplay.new())
	display.show_spill(
		InfluenceZone.project(Domain.Kind.FOREST, [Vector2i(3, -3)] as Array[Vector2i], 1),
		RealmGeometry.new()
	)
	assert_eq(display.spilled_hexes().size(), 3)


func test_a_swell_leaves_less_to_spill() -> void:
	var geometry := RealmGeometry.new()
	geometry.swell()
	var display: SpillDisplay = add_child_autofree(SpillDisplay.new())
	display.show_spill(
		InfluenceZone.project(Domain.Kind.FOREST, [Vector2i(3, -1)] as Array[Vector2i], 1),
		geometry
	)
	assert_eq(display.spilled_hexes(), [] as Array[Vector2i], "ring 4 fills it in")


func test_clearing_removes_the_spill() -> void:
	var display: SpillDisplay = add_child_autofree(SpillDisplay.new())
	display.show_spill(
		InfluenceZone.project(Domain.Kind.FOREST, [Vector2i(3, -1)] as Array[Vector2i], 1),
		RealmGeometry.new()
	)
	display.clear()
	assert_eq(display.spilled_hexes(), [] as Array[Vector2i])


func test_a_spill_is_not_solid_so_it_never_shadows_the_cursor_ray() -> void:
	var display: SpillDisplay = add_child_autofree(SpillDisplay.new())
	display.show_spill(
		InfluenceZone.project(Domain.Kind.FOREST, [Vector2i(3, -1)] as Array[Vector2i], 1),
		RealmGeometry.new()
	)
	assert_gt(display.get_child_count(), 0)
	for child in display.get_children():
		assert_false(child is CollisionObject3D, "spill carries no collision")
