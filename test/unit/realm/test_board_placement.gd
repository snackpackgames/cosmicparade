extends GutTest
## One piece on the board: its hexes, its orientation, and the zone it asks its piece for.


func _piece(shape: Footprint.Shape, domain: Domain.Kind, radius: int) -> Furniture:
	var piece := Furniture.new()
	piece.shape = shape
	piece.domain = domain
	piece.zone_radius = radius
	return piece


func test_a_placement_projects_one_zone_from_all_its_hexes() -> void:
	var hexes := Footprint.occupied(
		Footprint.Shape.STRAIGHT, 0, Vector2i.ZERO, Vector2i.ZERO
	)
	var placement := BoardPlacement.new(
		_piece(Footprint.Shape.STRAIGHT, Domain.Kind.FOREST, 1), 0, hexes
	)
	assert_eq(placement.zone().hex_count(), 13)
	assert_eq(placement.zone().domain, Domain.Kind.FOREST)


func test_a_placement_remembers_its_orientation() -> void:
	var placement := BoardPlacement.new(
		_piece(Footprint.Shape.SINGLE, Domain.Kind.GALE, 1), 4, [Vector2i.ZERO] as Array[Vector2i]
	)
	assert_eq(placement.orientation, 4)


func _single(domain: Domain.Kind, radius: int) -> Furniture:
	return _piece(Footprint.Shape.SINGLE, domain, radius)


func test_a_placement_asks_its_piece_what_to_project() -> void:
	var placement := BoardPlacement.new(
		_single(Domain.Kind.STONE, 1), 0, [Vector2i.ZERO] as Array[Vector2i]
	)
	assert_eq(placement.zone().domain, Domain.Kind.STONE)


func test_a_placement_of_a_piece_that_projects_nothing_has_no_zone() -> void:
	var placement := BoardPlacement.new(BoardPiece.new(), 0, [Vector2i.ZERO] as Array[Vector2i])
	assert_null(placement.zone())


func test_the_state_omits_a_placement_that_projects_nothing() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/75 — a null zone is absent
	# from the tally, not a zero entry in it.
	var state := RealmState.new(RealmGeometry.new())
	state.place(BoardPlacement.new(BoardPiece.new(), 0, [Vector2i.ZERO] as Array[Vector2i]))
	state.place(
		BoardPlacement.new(_single(Domain.Kind.GALE, 1), 0, [Vector2i(2, 0)] as Array[Vector2i])
	)
	assert_eq(state.zones().size(), 1)
