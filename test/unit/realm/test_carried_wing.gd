extends GutTest
## A wing in hand: the same verb, a different thing carried.


func _disc() -> WingShape:
	return load("res://data/realm/wing_shape/disc.tres")


func _stool() -> Furniture:
	return load("res://data/realm/furniture/mushroom_stool.tres")


func _bench() -> Furniture:
	return load("res://data/realm/furniture/fern_bench.tres")


func _board_with_a_wing() -> Array:
	var geometry := RealmGeometry.new()
	geometry.swell()
	geometry.swell()
	geometry.attach(_disc(), 0, Vector2i(7, -1))
	return [geometry, RealmState.new(geometry)]


# (7, -1) and (1, 6) are legal disc anchors against a radius-5 core, and most hexes
# are not: a disc centred in ring 6 always reaches a ring-5 hex and so overlaps the
# core, while one centred further out does not touch it at all. These two sit in ring
# 7 with their inner pair in ring 6, edge-adjacent to ring 5. If a test here fails,
# fix the code — do not move the anchor.


func test_a_wing_cycles_only_its_distinct_orientations() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/61
	assert_eq(CarriedWing.new(_disc(), Vector2i.ZERO, -1).orientation_count(), 1)
	assert_eq(
		CarriedWing.new(
			load("res://data/realm/wing_shape/trapezoid.tres"), Vector2i.ZERO, -1
		).orientation_count(),
		6
	)


func test_a_wing_projects_no_influence() -> void:
	assert_null(CarriedWing.new(_disc(), Vector2i.ZERO, -1).zone_at(Vector2i.ZERO, 0))


func test_a_wing_asks_nothing_of_the_ground_it_lands_on() -> void:
	assert_eq(CarriedWing.new(_disc(), Vector2i.ZERO, -1).describe_requirements(), [])


func test_a_wing_must_land_edge_adjacent_to_the_board() -> void:
	var parts := _board_with_a_wing()
	var carried := CarriedWing.new(_disc(), Vector2i.ZERO, -1)
	assert_false(carried.verdict_at(Vector2i(20, 0), 0, parts[1]).allowed)
	assert_true(carried.verdict_at(Vector2i(1, 6), 0, parts[1]).allowed)


func test_a_wing_may_not_land_on_the_board() -> void:
	var parts := _board_with_a_wing()
	assert_false(
		CarriedWing.new(_disc(), Vector2i.ZERO, -1).verdict_at(
			Vector2i.ZERO, 0, parts[1]
		).allowed
	)


func test_a_refused_siting_marks_the_whole_figure_and_no_requirement() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/62 -- a wing has no criteria,
	# so the requirement list has nothing to mark and stays hidden.
	var parts := _board_with_a_wing()
	var carried := CarriedWing.new(_disc(), Vector2i.ZERO, -1)
	var verdict := carried.verdict_at(Vector2i(20, 0), 0, parts[1])
	assert_eq(verdict.failing_hexes, carried.hexes_at(Vector2i(20, 0), 0))
	assert_eq(verdict.failing_criteria, [])


func test_a_wing_carries_the_furniture_standing_wholly_on_it() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/53
	var parts := _board_with_a_wing()
	var state: RealmState = parts[1]
	state.place(FurniturePlacement.new(_stool(), 0, [Vector2i(7, -1)] as Array[Vector2i]))
	var carried := CarriedWing.new(_disc(), Vector2i(7, -1), 0)
	carried.detach(state)
	assert_null(state.occupant_at(Vector2i(7, -1)))
	carried.commit(Vector2i(1, 6), 0, state)
	assert_not_null(state.occupant_at(Vector2i(1, 6)), "it travelled with the wing")
	assert_eq(carried.displaced, [], "nothing was straddling")


func test_a_piece_straddling_the_seam_is_returned_to_the_player() -> void:
	var parts := _board_with_a_wing()
	var state: RealmState = parts[1]
	var hexes := Footprint.occupied(Footprint.Shape.PAIR, 0, Vector2i(6, -1), Vector2i(1, 0))
	state.place(FurniturePlacement.new(_bench(), 0, hexes))
	var carried := CarriedWing.new(_disc(), Vector2i(7, -1), 0)
	carried.detach(state)
	carried.commit(Vector2i(1, 6), 0, state)
	assert_eq(carried.displaced.size(), 1, "lifted off rather than forbidden")
	assert_null(state.occupant_at(Vector2i(6, -1)))


func test_relocating_a_wing_never_loses_hexes() -> void:
	var parts := _board_with_a_wing()
	var geometry: RealmGeometry = parts[0]
	var before := geometry.hexes().size()
	var carried := CarriedWing.new(_disc(), Vector2i(7, -1), 0)
	carried.detach(parts[1])
	carried.commit(Vector2i(1, 6), 0, parts[1])
	assert_eq(geometry.hexes().size(), before)


func test_the_grabbed_hex_stays_under_the_target() -> void:
	# The pivot is the grab hex, as it is for furniture, so a wing grabbed by its rim
	# does not jump in the hand. https://github.com/snackpackgames/cosmicparade/issues/56
	var parts := _board_with_a_wing()
	var carried := CarriedWing.new(_disc(), Vector2i(6, -1), 0)
	carried.detach(parts[1])
	assert_true(carried.hexes_at(Vector2i(0, 6), 0).has(Vector2i(0, 6)))


func test_cancelling_puts_the_wing_and_everything_on_it_back() -> void:
	var parts := _board_with_a_wing()
	var geometry: RealmGeometry = parts[0]
	var state: RealmState = parts[1]
	state.place(FurniturePlacement.new(_stool(), 0, [Vector2i(7, -1)] as Array[Vector2i]))
	var straddler := FurniturePlacement.new(
		_bench(), 0, Footprint.occupied(Footprint.Shape.PAIR, 0, Vector2i(6, -1), Vector2i(1, 0))
	)
	state.place(straddler)
	var carried := CarriedWing.new(_disc(), Vector2i(7, -1), 0)
	carried.detach(state)
	carried.restore(state)
	assert_eq(geometry.hexes().size(), 98, "the wing is back")
	assert_true(geometry.has_hex(Vector2i(7, -1)), "at its original anchor")
	assert_not_null(state.occupant_at(Vector2i(7, -1)), "and so is what stood on it")
	assert_eq(
		state.occupant_at(Vector2i(6, -1)), straddler, "cancel means the straddler never moved"
	)
	assert_eq(carried.displaced, [], "nothing was returned to the player")


func test_a_lift_that_would_orphan_the_board_leaves_everything_alone() -> void:
	# Ruling 1: wings chain, so lifting the one another hangs off would float hexes.
	var geometry := RealmGeometry.new()
	geometry.swell()
	geometry.swell()
	geometry.attach(_disc(), 0, Vector2i(7, -1))
	geometry.attach(_disc(), 0, Vector2i(10, -2))
	var state := RealmState.new(geometry)
	state.place(FurniturePlacement.new(_stool(), 0, [Vector2i(7, -1)] as Array[Vector2i]))
	assert_false(geometry.can_lift_wing(0), "the outer wing hangs off this one")
	CarriedWing.new(_disc(), Vector2i(7, -1), 0).detach(state)
	assert_eq(geometry.hexes().size(), 105, "the board is untouched")
	assert_not_null(state.occupant_at(Vector2i(7, -1)), "and so is what stands on it")


func test_a_wing_turned_in_hand_turns_what_stands_on_it() -> void:
	# The travellers keep the same offsets relative to the wing, so a wing laid down a
	# turn further round carries its furniture round with it.
	# https://github.com/snackpackgames/cosmicparade/issues/53
	var geometry := RealmGeometry.new()
	geometry.swell()
	geometry.swell()
	var triangle: WingShape = load("res://data/realm/wing_shape/triangle.tres")
	geometry.attach(triangle, 0, Vector2i(6, 0))
	var state := RealmState.new(geometry)
	state.place(FurniturePlacement.new(_stool(), 0, [Vector2i(8, 0)] as Array[Vector2i]))
	var carried := CarriedWing.new(triangle, Vector2i(6, 0), 0)
	carried.detach(state)
	carried.commit(Vector2i(6, 0), 1, state)
	var expected := Vector2i(6, 0) + HexCoordinates.rotate(Vector2i(2, 0), 1)
	assert_not_null(state.occupant_at(expected), "it rode round with the ground")
	assert_eq(state.occupant_at(expected).orientation, 1, "and turned with it")


# Review Focus 5: criteria are a gate checked once, never re-checked.
func test_a_wing_landing_beside_a_rim_piece_leaves_it_exactly_where_it_is() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/30 -- the board can
	# legally hold states it cannot produce.
	var geometry := RealmGeometry.new()
	geometry.swell()
	geometry.swell()
	var state := RealmState.new(geometry)
	var stone: Furniture = load("res://data/realm/furniture/standing_stone.tres")
	var placement := FurniturePlacement.new(stone, 0, [Vector2i(5, 0)] as Array[Vector2i])
	state.place(placement)
	assert_true(geometry.is_edge_hex(Vector2i(5, 0)), "placed on the rim under require_edge")
	geometry.attach(_disc(), 0, Vector2i(7, -1))
	assert_eq(state.occupant_at(Vector2i(5, 0)), placement, "still there, never re-validated")
