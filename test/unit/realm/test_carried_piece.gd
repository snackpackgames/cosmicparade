extends GutTest
## A board piece in hand: furniture, a shrine or the Altar, through one carried type.


func _stool() -> Furniture:
	return load("res://data/realm/furniture/mushroom_stool.tres")


func _bench() -> Furniture:
	return load("res://data/realm/furniture/fern_bench.tres")


# A placeable built for an inventory lift: no hexes, because it stands nowhere yet.
func _unplaced(piece: BoardPiece) -> BoardPlacement:
	return BoardPlacement.new(piece, 0, [] as Array[Vector2i])


func test_the_grabbed_hex_stays_under_the_target() -> void:
	var carried := CarriedPiece.new(_unplaced(_bench()), Vector2i(1, 0))
	for orientation in 6:
		assert_true(carried.hexes_at(Vector2i(1, -1), orientation).has(Vector2i(1, -1)))


func test_furniture_always_offers_six_orientations() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/56 -- the art has a
	# facing even where the footprint has no asymmetry.
	assert_eq(CarriedPiece.new(_unplaced(_stool()), Vector2i.ZERO).orientation_count(), 6)


# Review Focus 4: "unplaced" is derived from having no hexes, and from nothing else.
func test_a_placeable_from_inventory_has_no_hexes_and_no_orientation_of_its_own() -> void:
	var carried := CarriedPiece.new(_unplaced(_stool()), Vector2i.ZERO)
	assert_eq(carried.own_orientation(), -1, "the carry's sticky orientation applies")
	assert_eq(carried.hexes_at(Vector2i(1, 0), 0), [Vector2i(1, 0)] as Array[Vector2i])


func test_a_placeable_lifted_from_the_board_keeps_its_own_orientation() -> void:
	var placed := BoardPlacement.new(_stool(), 5, [Vector2i.ZERO] as Array[Vector2i])
	assert_eq(CarriedPiece.new(placed, Vector2i.ZERO).own_orientation(), 5)


func test_detaching_a_piece_lifted_from_the_board_vacates_its_hexes() -> void:
	var state := RealmState.new(RealmGeometry.new())
	var origin := BoardPlacement.new(_stool(), 0, [Vector2i.ZERO] as Array[Vector2i])
	state.place(origin)
	CarriedPiece.new(origin, Vector2i.ZERO).detach(state)
	assert_null(state.occupant_at(Vector2i.ZERO))
	assert_eq(state.zones().size(), 0, "its influence is gone for the whole carry")


func test_detaching_a_placeable_from_inventory_leaves_the_board_alone() -> void:
	var state := RealmState.new(RealmGeometry.new())
	state.place(BoardPlacement.new(_stool(), 0, [Vector2i.ZERO] as Array[Vector2i]))
	CarriedPiece.new(_unplaced(_stool()), Vector2i.ZERO).detach(state)
	assert_eq(state.placements.size(), 1, "it stands nowhere, so there is nothing to leave")


func test_cancelling_puts_a_lifted_placeable_back_at_its_original_pose() -> void:
	var state := RealmState.new(RealmGeometry.new())
	var placed := BoardPlacement.new(_stool(), 3, [Vector2i.ZERO] as Array[Vector2i])
	state.place(placed)
	var carried := CarriedPiece.new(placed, Vector2i.ZERO)
	carried.detach(state)
	carried.restore(state)
	assert_eq(state.occupant_at(Vector2i.ZERO), placed)
	assert_eq(state.occupant_at(Vector2i.ZERO).orientation, 3)


func test_cancelling_a_lift_from_inventory_writes_nothing_to_the_board() -> void:
	var state := RealmState.new(RealmGeometry.new())
	var carried := CarriedPiece.new(_unplaced(_stool()), Vector2i.ZERO)
	carried.detach(state)
	carried.restore(state)
	assert_eq(state.placements.size(), 0, "a placeable with no hexes was never on the board")


func test_committing_places_the_very_placeable_that_was_carried() -> void:
	var state := RealmState.new(RealmGeometry.new())
	var carried := CarriedPiece.new(_unplaced(_stool()), Vector2i.ZERO)
	carried.commit(Vector2i(1, 0), 4, state)
	assert_eq(state.placements.size(), 1)
	assert_eq(state.placements[0], carried.placeable, "one object, not a copy")
	assert_eq(state.occupant_at(Vector2i(1, 0)).orientation, 4)


func test_committing_replaces_the_pose_and_never_edits_the_lifted_placement() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/131 -- the load-bearing
	# constraint: commit replaces the pose rather than mutating the placement it was handed,
	# which is why the adapter needs no remembered original and why a cancel restores the
	# piece instead of silently moving it.
	var state := RealmState.new(RealmGeometry.new())
	var placed := BoardPlacement.new(_stool(), 3, [Vector2i.ZERO] as Array[Vector2i])
	state.place(placed)
	var carried := CarriedPiece.new(placed, Vector2i.ZERO)
	carried.detach(state)
	carried.commit(Vector2i(1, 0), 4, state)
	assert_eq(placed.orientation, 3, "the lifted placement is untouched")
	assert_eq(placed.hexes, [Vector2i.ZERO] as Array[Vector2i])
	assert_eq(state.occupant_at(Vector2i(1, 0)).orientation, 4, "the replacement stands")


func test_a_piece_that_projects_nothing_is_judged_without_a_zone() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/77 -- the Altar projects
	# nothing, so there is no candidate zone to judge it against. Not a refusal.
	var state := RealmState.new(RealmGeometry.new())
	var verdict := PlacementRules.verdict(
		_unplaced(BoardPiece.new()), 0, Vector2i.ZERO, Vector2i.ZERO, state
	)
	assert_true(verdict.allowed)


func test_carrying_a_piece_that_projects_nothing_aims_a_null_zone() -> void:
	var carried := CarriedPiece.new(_unplaced(BoardPiece.new()), Vector2i.ZERO)
	assert_null(carried.zone_at(Vector2i.ZERO, 0))


func test_the_aimed_zone_grows_from_the_hexes_it_would_occupy() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/77 -- the zone follows the
	# candidate footprint, not the hexes the placeable stands on: a placeable lifted from
	# inventory stands on none, and its three-hex bench still reaches thirteen.
	var carried := CarriedPiece.new(_unplaced(_bench()), Vector2i(1, 0))
	assert_eq(carried.zone_at(Vector2i.ZERO, 0).hex_count(), 13)


func test_moving_a_fed_shrine_does_not_empty_its_vessel() -> void:
	# Rearranging is free (adr/0009), so a vessel must not empty itself because the player
	# shifted the shrine one hex. A piece lifted from the board is put back down as the
	# same placement, moved, so whatever runtime state it carries survives.
	# https://github.com/snackpackgames/cosmicparade/issues/75
	var state := RealmState.new(RealmGeometry.new())
	var shrine := Shrine.new()
	shrine.zone_source = OfferingVessel.new()
	var fruit := Fruit.new()
	fruit.domain = Domain.Kind.WETLAND
	var origin := BoardPlacement.new(shrine, 0, [Vector2i.ZERO] as Array[Vector2i])
	origin.offer(fruit)
	state.place(origin)

	var carried := CarriedPiece.new(origin, Vector2i.ZERO)
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
	var shrine := Shrine.new()
	shrine.zone_source = OfferingVessel.new()
	CarriedPiece.new(_unplaced(shrine), Vector2i.ZERO).commit(Vector2i.ZERO, 0, state)
	assert_eq(state.vessel_placements().size(), 1)
