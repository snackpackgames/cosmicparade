extends GutTest


func _context(occupied: Array[Vector2i]) -> PlacementContext:
	return PlacementContext.new(
		RealmState.new(RealmGeometry.new()), occupied, [] as Array[InfluenceZone]
	)


func test_requiring_the_edge_passes_on_the_rim_and_fails_in_the_middle() -> void:
	var criterion := BoardPositionCriterion.new()
	criterion.require_edge = true
	assert_eq(
		criterion.failing_hexes(_context([Vector2i(3, 0)] as Array[Vector2i])),
		[] as Array[Vector2i]
	)
	assert_eq(
		criterion.failing_hexes(_context([Vector2i.ZERO] as Array[Vector2i])),
		[Vector2i.ZERO] as Array[Vector2i]
	)


func test_requiring_the_interior_is_the_same_test_inverted() -> void:
	var criterion := BoardPositionCriterion.new()
	criterion.require_edge = false
	assert_eq(
		criterion.failing_hexes(_context([Vector2i.ZERO] as Array[Vector2i])),
		[] as Array[Vector2i]
	)
	assert_eq(
		criterion.failing_hexes(_context([Vector2i(3, 0)] as Array[Vector2i])).size(), 1
	)


func test_every_hex_of_the_footprint_must_satisfy_it() -> void:
	var criterion := BoardPositionCriterion.new()
	criterion.require_edge = true
	var occupied: Array[Vector2i] = [Vector2i(3, 0), Vector2i(2, 0)]
	assert_eq(criterion.failing_hexes(_context(occupied)), [Vector2i(2, 0)] as Array[Vector2i])


func test_an_off_board_hex_is_not_an_edge_hex() -> void:
	# Siting refuses it before criteria run; the criterion on its own just says "not edge".
	var criterion := BoardPositionCriterion.new()
	criterion.require_edge = true
	assert_eq(criterion.failing_hexes(_context([Vector2i(4, 0)] as Array[Vector2i])).size(), 1)
