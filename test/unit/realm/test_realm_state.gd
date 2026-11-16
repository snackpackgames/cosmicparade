extends GutTest
## The committed board: the placements on it, and the zones recomputed from them.


func _stool() -> Furniture:
	return load("res://data/realm/furniture/mushroom_stool.tres")


func _bench() -> Furniture:
	return load("res://data/realm/furniture/fern_bench.tres")


func _stool_at(hex: Vector2i) -> BoardPlacement:
	return BoardPlacement.new(_stool(), 0, [hex] as Array[Vector2i])


func _bench_at(hex: Vector2i, orientation: int) -> BoardPlacement:
	return BoardPlacement.new(
		_bench(), orientation,
		Footprint.occupied(Footprint.Shape.STRAIGHT, orientation, hex, Vector2i(1, 0))
	)


func test_a_fresh_realm_has_no_placements_and_no_zones() -> void:
	var state := RealmState.new(RealmGeometry.new())
	assert_eq(state.placements.size(), 0)
	assert_eq(state.zones().size(), 0)


func test_zones_are_recomputed_from_the_placements_every_call() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/59 — never stored.
	var state := RealmState.new(RealmGeometry.new())
	var placement := _stool_at(Vector2i.ZERO)
	state.place(placement)
	assert_eq(state.zones().size(), 1)
	state.remove(placement)
	assert_eq(state.zones().size(), 0)


func test_every_hex_of_a_footprint_is_occupied() -> void:
	var state := RealmState.new(RealmGeometry.new())
	var bench := _bench_at(Vector2i.ZERO, 0)
	state.place(bench)
	for hex: Vector2i in bench.hexes:
		assert_eq(state.occupant_at(hex), bench, "%s" % hex)
	assert_null(state.occupant_at(Vector2i(0, 2)))


func test_placements_within_finds_only_pieces_wholly_inside_the_hexes() -> void:
	var state := RealmState.new(RealmGeometry.new())
	var bench := _bench_at(Vector2i.ZERO, 0)
	state.place(bench)
	assert_eq(state.placements_within(bench.hexes), [bench])
	assert_eq(state.placements_within([Vector2i.ZERO] as Array[Vector2i]), [])


func test_placements_touching_finds_a_piece_overlapping_the_hexes_at_all() -> void:
	var state := RealmState.new(RealmGeometry.new())
	var bench := _bench_at(Vector2i.ZERO, 0)
	state.place(bench)
	assert_eq(state.placements_touching([Vector2i.ZERO] as Array[Vector2i]), [bench])
