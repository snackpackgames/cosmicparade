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
	var projection := DomainProjection.new()
	projection.domain = domain
	projection.reach = radius
	piece.zone_source = projection
	piece.shape = Footprint.Shape.SINGLE
	return piece


func _state() -> RealmState:
	return RealmState.new(RealmGeometry.new())


func _furniture_at(hex: Vector2i) -> BoardPlacement:
	return BoardPlacement.new(_piece(Domain.Kind.FOREST, 1), 0, [hex] as Array[Vector2i])


# Places a fed shrine at `hex` and returns its placement.
func _place_shrine(state: RealmState, hex: Vector2i, domain: Domain.Kind) -> ShrinePlacement:
	var placement := ShrinePlacement.new(_shrine(), 0, [hex] as Array[Vector2i])
	placement.offering = _fruit(domain)
	state.place(placement)
	return placement


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


func test_shrine_zones_are_only_the_shrines_and_only_the_fed_ones() -> void:
	var state := _state()
	_place_shrine(state, Vector2i(-2, 0), Domain.Kind.FOREST)
	state.place(ShrinePlacement.new(_shrine(), 0, [Vector2i(2, 0)] as Array[Vector2i]))
	state.place(_furniture_at(Vector2i(0, 2)))
	assert_eq(state.zones().size(), 2)
	assert_eq(state.shrine_zones().size(), 1)


func test_emptying_a_vessel_drops_the_ground_and_leaves_the_piece_standing() -> void:
	# Review Focus 5. https://github.com/snackpackgames/cosmicparade/issues/38 — removal
	# lowers ground immediately; https://github.com/snackpackgames/cosmicparade/issues/55
	# — criteria are never re-checked, so nothing is displaced.
	var state := _state()
	var shrine := _place_shrine(state, Vector2i(1, 0), Domain.Kind.FOREST)
	state.place(_furniture_at(Vector2i.ZERO))
	assert_eq(Elevation.depth_at(Vector2i.ZERO, state.zones()), 1)

	shrine.offering = null

	assert_eq(Elevation.depth_at(Vector2i.ZERO, state.zones()), 0)
	assert_eq(state.placements.size(), 2)
	assert_not_null(state.occupant_at(Vector2i.ZERO))


func test_a_new_realm_holds_two_shrines_in_stock() -> void:
	var state := _state()
	assert_eq(state.shrine_capacity, 2)
	assert_eq(state.shrines_in_stock(), 2)


func test_placing_a_shrine_takes_it_out_of_stock() -> void:
	var state := _state()
	_place_shrine(state, Vector2i(-2, 0), Domain.Kind.FOREST)
	assert_eq(state.shrines_in_stock(), 1)


func test_furniture_does_not_come_out_of_shrine_stock() -> void:
	var state := _state()
	state.place(_furniture_at(Vector2i(0, 2)))
	assert_eq(state.shrines_in_stock(), 2)


func test_shrine_placements_are_only_the_shrines() -> void:
	var state := _state()
	_place_shrine(state, Vector2i(-2, 0), Domain.Kind.FOREST)
	state.place(_stool_at(Vector2i(0, 2)))
	assert_eq(state.shrine_placements().size(), 1)
	assert_eq(state.placements.size(), 2)


func test_lifting_a_shrine_off_the_board_puts_it_back_in_stock() -> void:
	# Stock is derived, so there is no inventory object to desynchronise: what is in hand
	# is what is not on the board.
	var state := _state()
	var shrine := _place_shrine(state, Vector2i(-2, 0), Domain.Kind.FOREST)
	state.remove(shrine)
	assert_eq(state.shrines_in_stock(), 2)


func _altar() -> Altar:
	var altar := Altar.new()
	altar.piece_name = "test altar"
	altar.shape = Footprint.Shape.TRIANGLE
	altar.criteria = [LevelFootprintCriterion.new()] as Array[PlacementCriterion]
	return altar


func test_a_new_realm_stands_its_altar_on_the_origin() -> void:
	var state := _state()
	state.place_altar(_altar())
	for hex: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, -1)]:
		assert_not_null(state.occupant_at(hex))
	assert_eq(state.altar_placement.hexes.size(), 3)


func test_the_altar_contributes_no_zone() -> void:
	var state := _state()
	state.place_altar(_altar())
	assert_eq(state.zones().size(), 0)


func _disc() -> WingShape:
	return load("res://data/realm/wing_shape/disc.tres")


## A radius-5 core with a disc wing anchored at (7, -1), the wing's index 0.
func _state_with_a_wing() -> RealmState:
	var state := _state()
	state.geometry.swell()
	state.geometry.swell()
	assert_false(state.geometry.attach(_disc(), 0, Vector2i(7, -1)).is_empty())
	return state


# How many of `hexes` stand on the wing at `wing_index`.
func _on_wing(state: RealmState, wing_index: int, hexes: Array[Vector2i]) -> int:
	var wing_hexes := state.geometry.wings[wing_index].hexes()
	var count := 0
	for hex in hexes:
		if wing_hexes.has(hex):
			count += 1
	return count


func test_a_wing_carrying_the_whole_altar_can_still_be_lifted() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/53 relocates a wing with its
	# contents; an Altar wholly aboard travels.
	var state := _state_with_a_wing()
	var aboard := Footprint.occupied(
		Footprint.Shape.TRIANGLE, 0, Vector2i(7, -1), Vector2i.ZERO
	)
	assert_eq(_on_wing(state, 0, aboard), aboard.size(), "every hex of it is on the wing")
	state.altar_placement = BoardPlacement.new(_altar(), 0, aboard)
	assert_false(state.altar_straddles_wing(0))


func test_an_altar_nowhere_near_the_wing_leaves_it_liftable() -> void:
	var state := _state_with_a_wing()
	state.place_altar(_altar())
	assert_eq(_on_wing(state, 0, state.altar_placement.hexes), 0)
	assert_false(state.altar_straddles_wing(0))


func test_an_altar_across_the_seam_pins_the_wing() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/77 -- the straddling path
	# returns furniture to the player, and the Altar has nowhere to be returned to.
	var state := _state_with_a_wing()
	# The triangle-three laid from (5, 0) reaches (6, 0) and (6, -1) on the wing's near edge
	# and keeps (5, 0) on the core rim.
	var across := Footprint.occupied(
		Footprint.Shape.TRIANGLE, 0, Vector2i(5, 0), Vector2i.ZERO
	)
	var aboard := _on_wing(state, 0, across)
	assert_gt(aboard, 0, "at least one hex on the wing")
	assert_lt(aboard, across.size(), "and at least one off it")

	state.altar_placement = BoardPlacement.new(_altar(), 0, across)

	assert_true(state.altar_straddles_wing(0))


func test_a_realm_with_no_altar_standing_pins_nothing() -> void:
	var state := _state_with_a_wing()
	assert_false(state.altar_straddles_wing(0))
	assert_false(state.altar_straddles_wing(-1))
	assert_false(state.altar_straddles_wing(1))


func test_a_straddling_shrine_goes_back_to_stock_by_being_removed() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/74 gave shrines the
	# destination the Altar lacks, and stock is derived -- so removal is the whole of it.
	var state := _state()
	var shrine := _place_shrine(state, Vector2i(-2, 0), Domain.Kind.FOREST)
	assert_eq(state.shrines_in_stock(), 1)

	state.remove(shrine)

	assert_eq(state.shrines_in_stock(), 2)
	assert_null(state.occupant_at(Vector2i(-2, 0)))


func test_the_altars_placement_follows_it_when_it_is_relocated() -> void:
	# The field is an index over `placements`, kept by the mutations, because the Altar is
	# relocated through the one carry path: a stale footprint would go on pinning a wing the
	# Altar had already been carried off.
	var state := _state()
	state.place_altar(_altar())
	state.remove(state.altar_placement)
	assert_null(state.altar_placement, "lifted, it stands nowhere")

	var moved := Footprint.occupied(
		Footprint.Shape.TRIANGLE, 0, Vector2i(-2, 0), Vector2i.ZERO
	)
	state.place(BoardPlacement.new(_altar(), 0, moved))

	assert_eq(state.altar_placement.hexes, moved)
