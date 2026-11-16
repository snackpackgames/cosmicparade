extends GutTest
## The influence spill past the board's edge.


func _zone(hex: Vector2i) -> InfluenceZone:
	return InfluenceZone.project(Domain.Kind.FOREST, [hex] as Array[Vector2i], 1)


func _display() -> SpillDisplay:
	return add_child_autofree(SpillDisplay.new())


func test_a_zone_wholly_on_the_board_spills_nothing() -> void:
	var display := _display()
	display.show_spill(_zone(Vector2i.ZERO), RealmGeometry.new())
	assert_eq(display.spilled_hexes(), [] as Array[Vector2i])


func test_a_rim_placement_spills_the_coordinates_with_no_hex_under_them() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/59
	var display := _display()
	display.show_spill(_zone(Vector2i(3, -1)), RealmGeometry.new())
	assert_eq(display.spilled_hexes().size(), 2)


func test_a_corner_placement_spills_more_than_a_rim_one() -> void:
	var display := _display()
	display.show_spill(_zone(Vector2i(3, 0)), RealmGeometry.new())
	assert_eq(display.spilled_hexes().size(), 3)


func test_a_swell_leaves_less_to_spill() -> void:
	var geometry := RealmGeometry.new()
	geometry.swell()
	var display := _display()
	display.show_spill(_zone(Vector2i(3, -1)), geometry)
	assert_eq(display.spilled_hexes(), [] as Array[Vector2i], "ring 4 fills it in")


func test_clearing_removes_the_spill() -> void:
	var display := _display()
	display.show_spill(_zone(Vector2i(3, -1)), RealmGeometry.new())
	display.clear()
	assert_eq(display.spilled_hexes(), [] as Array[Vector2i])


func test_spill_meshes_carry_no_collision() -> void:
	var display := _display()
	display.show_spill(_zone(Vector2i(3, -1)), RealmGeometry.new())
	for child in display.get_children():
		assert_false(child is CollisionObject3D)
