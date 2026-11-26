extends GutTest
## One piece on the board: its hexes, its orientation, and the zone it asks its piece for.


func _piece(shape: Footprint.Shape, domain: Domain.Kind, radius: int) -> Furniture:
	var piece := Furniture.new()
	piece.shape = shape
	var projection := DomainProjection.new()
	projection.domain = domain
	projection.reach = radius
	piece.zone_source = projection
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


func test_a_placement_whose_piece_has_no_zone_source_projects_null() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/37 — null, never an empty zone.
	var placement := BoardPlacement.new(BoardPiece.new(), 0, [Vector2i.ZERO] as Array[Vector2i])
	assert_null(placement.zone())


func _fruit(domain: Domain.Kind) -> Fruit:
	var fruit := Fruit.new()
	fruit.domain = domain
	return fruit


func _shrine_piece() -> Shrine:
	var piece := Shrine.new()
	var vessel := OfferingVessel.new()
	vessel.reach = 2
	piece.zone_source = vessel
	return piece


func test_a_placement_built_from_a_vessel_piece_gets_its_own_vessel() -> void:
	var piece := _shrine_piece()
	var first := BoardPlacement.new(piece, 0, [Vector2i.ZERO] as Array[Vector2i])
	var second := BoardPlacement.new(piece, 0, [Vector2i(2, 0)] as Array[Vector2i])
	first.offer(_fruit(Domain.Kind.FOREST))
	assert_true(first.holds_offering())
	assert_false(second.holds_offering(), "one authored piece, two vessels")
	assert_false(piece.zone_source.holds_offering(), "the authored resource stays unfed")


func test_relocating_carries_the_vessel_and_its_contents() -> void:
	var placement := BoardPlacement.new(
		_shrine_piece(), 0, [Vector2i.ZERO] as Array[Vector2i]
	)
	placement.offer(_fruit(Domain.Kind.WETLAND))
	var moved := placement.relocated(0, [Vector2i(1, 0)] as Array[Vector2i])
	assert_true(moved.holds_offering(), "rearranging is free (adr/0009)")
	assert_eq(moved.zone().domain, Domain.Kind.WETLAND)


func test_a_placement_whose_piece_has_no_zone_source_holds_no_vessel() -> void:
	var placement := BoardPlacement.new(
		BoardPiece.new(), 0, [Vector2i.ZERO] as Array[Vector2i]
	)
	assert_false(placement.can_hold_offering())
	assert_false(placement.holds_offering())
	placement.offer(_fruit(Domain.Kind.FOREST))
	placement.empty_vessel()
	assert_null(placement.zone())
