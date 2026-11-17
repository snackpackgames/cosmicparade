extends GutTest
## A board piece in hand: furniture, a shrine or the Altar, through one carried type.


func _stool() -> Furniture:
	return load("res://data/realm/furniture/mushroom_stool.tres")


func _bench() -> Furniture:
	return load("res://data/realm/furniture/fern_bench.tres")


func test_the_grabbed_hex_stays_under_the_target() -> void:
	var carried := CarriedPiece.new(_bench(), Vector2i(1, 0), null)
	for orientation in 6:
		assert_true(carried.hexes_at(Vector2i(1, -1), orientation).has(Vector2i(1, -1)))


func test_furniture_always_offers_six_orientations() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/56 -- the art has a
	# facing even where the footprint has no asymmetry.
	assert_eq(CarriedPiece.new(_stool(), Vector2i.ZERO, null).orientation_count(), 6)


func test_detaching_a_piece_lifted_from_the_board_vacates_its_hexes() -> void:
	var state := RealmState.new(RealmGeometry.new())
	var origin := BoardPlacement.new(_stool(), 0, [Vector2i.ZERO] as Array[Vector2i])
	state.place(origin)
	CarriedPiece.new(_stool(), Vector2i.ZERO, origin).detach(state)
	assert_null(state.occupant_at(Vector2i.ZERO))
	assert_eq(state.zones().size(), 0, "its influence is gone for the whole carry")


func test_restoring_puts_the_origin_placement_back_unchanged() -> void:
	var state := RealmState.new(RealmGeometry.new())
	var origin := BoardPlacement.new(_stool(), 3, [Vector2i.ZERO] as Array[Vector2i])
	state.place(origin)
	var carried := CarriedPiece.new(_stool(), Vector2i.ZERO, origin)
	carried.detach(state)
	carried.restore(state)
	assert_eq(state.occupant_at(Vector2i.ZERO), origin)
	assert_eq(state.occupant_at(Vector2i.ZERO).orientation, 3)


func test_committing_places_a_piece_at_the_target_with_the_carried_orientation() -> void:
	var state := RealmState.new(RealmGeometry.new())
	CarriedPiece.new(_stool(), Vector2i.ZERO, null).commit(Vector2i(1, 0), 4, state)
	assert_eq(state.placements.size(), 1)
	assert_eq(state.occupant_at(Vector2i(1, 0)).orientation, 4)


func test_a_piece_that_projects_nothing_is_judged_without_a_zone() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/77 -- the Altar projects
	# nothing, so there is no candidate zone to judge it against. Not a refusal.
	var state := RealmState.new(RealmGeometry.new())
	var verdict := PlacementRules.verdict(BoardPiece.new(), 0, Vector2i.ZERO, Vector2i.ZERO, state)
	assert_true(verdict.allowed)


func test_carrying_a_piece_that_projects_nothing_aims_a_null_zone() -> void:
	var carried := CarriedPiece.new(BoardPiece.new(), Vector2i.ZERO, null)
	assert_null(carried.zone_at(Vector2i.ZERO, 0))


func test_moving_a_fed_shrine_does_not_empty_its_vessel() -> void:
	# Rearranging is free (adr/0009), so a vessel must not empty itself because the player
	# shifted the shrine one hex. A piece lifted from the board is put back down as the
	# same placement, moved, so whatever runtime state it carries survives.
	# https://github.com/snackpackgames/cosmicparade/issues/75
	var state := RealmState.new(RealmGeometry.new())
	var shrine := Shrine.new()
	var fruit := Fruit.new()
	fruit.domain = Domain.Kind.WETLAND
	var origin := ShrinePlacement.new(shrine, 0, [Vector2i.ZERO] as Array[Vector2i])
	origin.offering = fruit
	state.place(origin)

	var carried := CarriedPiece.new(shrine, Vector2i.ZERO, origin)
	carried.detach(state)
	carried.commit(Vector2i(1, 0), 0, state)

	assert_eq(state.shrine_zones().size(), 1, "it is still projecting")
	assert_eq(state.shrine_zones()[0].domain, Domain.Kind.WETLAND)
	assert_true(state.shrine_zones()[0].covers(Vector2i(1, 0)), "from where it now stands")


func test_a_shrine_from_stock_lands_as_a_shrine_placement() -> void:
	# The carry asks the piece which placement it stands in, the same way it asks what it
	# projects — or a placed shrine would be invisible to the board as a shrine.
	# https://github.com/snackpackgames/cosmicparade/issues/74
	var state := RealmState.new(RealmGeometry.new())
	CarriedPiece.new(Shrine.new(), Vector2i.ZERO, null).commit(Vector2i.ZERO, 0, state)
	assert_eq(state.shrine_placements().size(), 1)
