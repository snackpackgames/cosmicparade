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


func _fruit(domain: Domain.Kind) -> Fruit:
	var fruit := Fruit.new()
	fruit.fruit_name = "test fruit"
	fruit.domain = domain
	return fruit


func _shrine() -> Shrine:
	var shrine := Shrine.new()
	shrine.piece_name = "test shrine"
	return shrine


func _piece(domain: Domain.Kind, radius: int) -> Furniture:
	var piece := Furniture.new()
	piece.piece_name = "test piece"
	piece.domain = domain
	piece.shape = Footprint.Shape.SINGLE
	piece.zone_radius = radius
	return piece


func _state() -> RealmState:
	return RealmState.new(RealmGeometry.new())


# Places a fed shrine at `hex` and returns its placement.
func _place_shrine(state: RealmState, hex: Vector2i, domain: Domain.Kind) -> ShrinePlacement:
	var placement := ShrinePlacement.new(_shrine(), 0, [hex] as Array[Vector2i])
	placement.offering = _fruit(domain)
	state.place(placement)
	return placement


func test_shrine_zones_are_only_the_shrines_and_only_the_fed_ones() -> void:
	var state := _state()
	_place_shrine(state, Vector2i(-2, 0), Domain.Kind.FOREST)
	state.place(ShrinePlacement.new(_shrine(), 0, [Vector2i(2, 0)] as Array[Vector2i]))
	state.place(
		BoardPlacement.new(_piece(Domain.Kind.FOREST, 1), 0, [Vector2i(0, 2)] as Array[Vector2i])
	)
	assert_eq(state.zones().size(), 2)
	assert_eq(state.shrine_zones().size(), 1)


func test_emptying_a_vessel_drops_the_ground_and_leaves_the_piece_standing() -> void:
	# Review Focus 5. https://github.com/snackpackgames/cosmicparade/issues/38 — removal
	# lowers ground immediately; https://github.com/snackpackgames/cosmicparade/issues/55
	# — criteria are never re-checked, so nothing is displaced.
	var state := _state()
	var shrine := _place_shrine(state, Vector2i(1, 0), Domain.Kind.FOREST)
	state.place(
		BoardPlacement.new(_piece(Domain.Kind.FOREST, 1), 0, [Vector2i(0, 0)] as Array[Vector2i])
	)
	assert_eq(Elevation.depth_at(Vector2i.ZERO, state.zones()), 1)

	shrine.offering = null

	assert_eq(Elevation.depth_at(Vector2i.ZERO, state.zones()), 0)
	assert_eq(state.placements.size(), 2)
	assert_not_null(state.occupant_at(Vector2i.ZERO))


func test_shrine_placements_are_only_the_shrines() -> void:
	var state := _state()
	_place_shrine(state, Vector2i(-2, 0), Domain.Kind.FOREST)
	state.place(_stool_at(Vector2i(0, 2)))
	assert_eq(state.shrine_placements().size(), 1)
	assert_eq(state.placements.size(), 2)
