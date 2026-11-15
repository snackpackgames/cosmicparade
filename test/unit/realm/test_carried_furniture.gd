extends GutTest
## A furniture piece in hand.


func _stool() -> Furniture:
	return load("res://data/realm/furniture/mushroom_stool.tres")


func _bench() -> Furniture:
	return load("res://data/realm/furniture/fern_bench.tres")


func test_the_grabbed_hex_stays_under_the_target() -> void:
	var carried := CarriedFurniture.new(_bench(), Vector2i(1, 0), null)
	for orientation in 6:
		assert_true(carried.hexes_at(Vector2i(1, -1), orientation).has(Vector2i(1, -1)))


func test_furniture_always_offers_six_orientations() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/56 -- the art has a
	# facing even where the footprint has no asymmetry.
	assert_eq(CarriedFurniture.new(_stool(), Vector2i.ZERO, null).orientation_count(), 6)


func test_detaching_a_piece_lifted_from_the_board_vacates_its_hexes() -> void:
	var state := RealmState.new(RealmGeometry.new())
	var origin := FurniturePlacement.new(_stool(), 0, [Vector2i.ZERO] as Array[Vector2i])
	state.place(origin)
	CarriedFurniture.new(_stool(), Vector2i.ZERO, origin).detach(state)
	assert_null(state.occupant_at(Vector2i.ZERO))
	assert_eq(state.zones().size(), 0, "its influence is gone for the whole carry")


func test_restoring_puts_the_origin_placement_back_unchanged() -> void:
	var state := RealmState.new(RealmGeometry.new())
	var origin := FurniturePlacement.new(_stool(), 3, [Vector2i.ZERO] as Array[Vector2i])
	state.place(origin)
	var carried := CarriedFurniture.new(_stool(), Vector2i.ZERO, origin)
	carried.detach(state)
	carried.restore(state)
	assert_eq(state.occupant_at(Vector2i.ZERO), origin)
	assert_eq(state.occupant_at(Vector2i.ZERO).orientation, 3)


func test_committing_places_a_piece_at_the_target_with_the_carried_orientation() -> void:
	var state := RealmState.new(RealmGeometry.new())
	CarriedFurniture.new(_stool(), Vector2i.ZERO, null).commit(Vector2i(1, 0), 4, state)
	assert_eq(state.placements.size(), 1)
	assert_eq(state.occupant_at(Vector2i(1, 0)).orientation, 4)
