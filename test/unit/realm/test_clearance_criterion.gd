extends GutTest


func _stool_at(hex: Vector2i) -> FurniturePlacement:
	var stool: Furniture = load("res://data/realm/furniture/mushroom_stool.tres")
	return FurniturePlacement.new(stool, 0, [hex] as Array[Vector2i])


func _context(occupied: Array[Vector2i], state: RealmState) -> PlacementContext:
	return PlacementContext.new(state, occupied, [] as Array[InfluenceZone])


func _clearance(distance: int) -> ClearanceCriterion:
	var criterion := ClearanceCriterion.new()
	criterion.distance = distance
	return criterion


func test_clearance_passes_on_an_empty_board() -> void:
	assert_eq(
		_clearance(1).failing_hexes(
			_context([Vector2i.ZERO] as Array[Vector2i], RealmState.new(RealmGeometry.new()))
		),
		[] as Array[Vector2i]
	)


func test_clearance_returns_the_blocking_hexes_so_they_can_be_marked() -> void:
	var state := RealmState.new(RealmGeometry.new())
	state.place(_stool_at(Vector2i(1, 0)))
	assert_eq(
		_clearance(1).failing_hexes(_context([Vector2i.ZERO] as Array[Vector2i], state)),
		[Vector2i(1, 0)] as Array[Vector2i]
	)


func test_a_piece_two_hexes_away_does_not_break_clearance_of_one() -> void:
	var state := RealmState.new(RealmGeometry.new())
	state.place(_stool_at(Vector2i(2, 0)))
	assert_eq(
		_clearance(1).failing_hexes(_context([Vector2i.ZERO] as Array[Vector2i], state)),
		[] as Array[Vector2i]
	)


func test_the_pieces_own_hexes_never_break_its_own_clearance() -> void:
	var occupied: Array[Vector2i] = [Vector2i.ZERO, Vector2i(1, 0)]
	assert_eq(
		_clearance(1).failing_hexes(_context(occupied, RealmState.new(RealmGeometry.new()))),
		[] as Array[Vector2i]
	)


# Review Focus 4: off-board means nothing is there.
func test_off_board_hexes_count_as_clear() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/55
	assert_eq(
		_clearance(2).failing_hexes(
			_context([Vector2i(3, 0)] as Array[Vector2i], RealmState.new(RealmGeometry.new()))
		),
		[] as Array[Vector2i]
	)
