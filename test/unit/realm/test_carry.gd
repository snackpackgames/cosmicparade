extends GutTest
## The carry state machine.


func _stool() -> Furniture:
	return load("res://data/realm/furniture/mushroom_stool.tres")


func _bench() -> Furniture:
	return load("res://data/realm/furniture/fern_bench.tres")


func _shrine() -> Shrine:
	return load("res://data/realm/shrine/plain_shrine.tres")


func _altar() -> Altar:
	return load("res://data/realm/altar/altar.tres")


# A placeable built for an inventory lift: no hexes, because it stands nowhere yet.
func _unplaced(piece: BoardPiece) -> BoardPlacement:
	return BoardPlacement.new(piece, 0, [] as Array[Vector2i])


func _carry(state: RealmState) -> Carry:
	var carry: Carry = add_child_autofree(Carry.new())
	carry.configure(state)
	return carry


func test_a_fresh_carry_is_idle() -> void:
	var carry := _carry(RealmState.new(RealmGeometry.new()))
	assert_false(carry.is_carrying())
	assert_null(carry.carried)


func test_lifting_enters_the_carry_and_announces_the_first_target() -> void:
	var carry := _carry(RealmState.new(RealmGeometry.new()))
	watch_signals(carry)
	carry.lift(CarriedPiece.new(_unplaced(_stool()), Vector2i.ZERO), Vector2i.ZERO)
	assert_true(carry.is_carrying())
	assert_signal_emitted(carry, "lifted")
	assert_signal_emitted(carry, "aimed")


func test_aiming_re_evaluates_validity_on_every_target() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/54 -- valid/refused is a
	# property of the current target, not a state of the verb.
	var state := RealmState.new(RealmGeometry.new())
	var carry := _carry(state)
	carry.lift(CarriedPiece.new(_unplaced(_bench()), Vector2i(1, 0)), Vector2i.ZERO)
	carry.aim(Vector2i(3, 0))
	assert_false(carry.verdict().allowed, "the far end hangs off the board")
	carry.aim(Vector2i.ZERO)
	assert_eq(carry.verdict().failing_hexes.size(), 3, "sited, but Forest >= 2 is short")


func test_placing_a_refused_target_is_inert_and_the_player_keeps_carrying() -> void:
	var state := RealmState.new(RealmGeometry.new())
	var carry := _carry(state)
	carry.lift(CarriedPiece.new(_unplaced(_bench()), Vector2i(1, 0)), Vector2i(3, 0))
	assert_false(carry.place())
	assert_true(carry.is_carrying())
	assert_eq(state.placements.size(), 0)


func test_placing_an_allowed_target_commits_and_returns_to_idle() -> void:
	var state := RealmState.new(RealmGeometry.new())
	var carry := _carry(state)
	watch_signals(carry)
	carry.lift(CarriedPiece.new(_unplaced(_stool()), Vector2i.ZERO), Vector2i(1, 0))
	assert_true(carry.place())
	assert_false(carry.is_carrying())
	assert_eq(state.placements.size(), 1)
	assert_signal_emitted(carry, "placed")


func test_cancel_returns_the_piece_to_its_origin_hex_and_orientation() -> void:
	var state := RealmState.new(RealmGeometry.new())
	var origin := BoardPlacement.new(_stool(), 2, [Vector2i.ZERO] as Array[Vector2i])
	state.place(origin)
	var carry := _carry(state)
	carry.lift(CarriedPiece.new(origin, Vector2i.ZERO), Vector2i.ZERO)
	carry.aim(Vector2i(2, 0))
	carry.rotate_once()
	carry.cancel()
	assert_false(carry.is_carrying())
	assert_eq(state.occupant_at(Vector2i.ZERO), origin)
	assert_eq(state.occupant_at(Vector2i.ZERO).orientation, 2)


func test_a_carried_piece_occupies_nothing() -> void:
	var state := RealmState.new(RealmGeometry.new())
	var origin := BoardPlacement.new(_stool(), 0, [Vector2i.ZERO] as Array[Vector2i])
	state.place(origin)
	var carry := _carry(state)
	carry.lift(CarriedPiece.new(origin, Vector2i.ZERO), Vector2i.ZERO)
	assert_null(state.occupant_at(Vector2i.ZERO))


# Review Focus 2: a carried piece occupies nothing, including its own old hexes.
func test_a_straight_three_can_shift_one_hex_along_its_own_axis() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/54
	var state := RealmState.new(RealmGeometry.new())
	state.place(BoardPlacement.new(_stool(), 0, [Vector2i(0, 1)] as Array[Vector2i]))
	var hexes := Footprint.occupied(Footprint.Shape.STRAIGHT, 0, Vector2i.ZERO, Vector2i(1, 0))
	var origin := BoardPlacement.new(_bench(), 0, hexes)
	state.place(origin)
	var carry := _carry(state)
	carry.lift(CarriedPiece.new(origin, Vector2i(1, 0)), Vector2i.ZERO)
	carry.aim(Vector2i(1, 0))
	# A siting refusal carries no failing criteria, so any criterion failing here proves the
	# footprint cleared siting: it did not collide with its own old hexes.
	assert_false(carry.verdict().failing_criteria.is_empty(), "it must not collide with itself")


func test_rotating_in_place_does_not_collide_with_itself() -> void:
	var state := RealmState.new(RealmGeometry.new())
	var hexes := Footprint.occupied(Footprint.Shape.STRAIGHT, 0, Vector2i.ZERO, Vector2i(1, 0))
	var origin := BoardPlacement.new(_bench(), 0, hexes)
	state.place(origin)
	var carry := _carry(state)
	carry.lift(CarriedPiece.new(origin, Vector2i(1, 0)), Vector2i.ZERO)
	for _step in 6:
		carry.rotate_once()
		assert_eq(carry.verdict().failing_hexes.size(), 3, "short on Forest, never blocked")


func test_rotation_wraps_through_the_carried_things_orientation_count() -> void:
	var carry := _carry(RealmState.new(RealmGeometry.new()))
	carry.lift(CarriedPiece.new(_unplaced(_stool()), Vector2i.ZERO), Vector2i.ZERO)
	for _step in 6:
		carry.rotate_once()
	assert_eq(carry.orientation, 0)


func test_a_piece_from_inventory_arrives_at_the_last_orientation_placed() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/56 -- sticky, and carry
	# state rather than board state.
	var state := RealmState.new(RealmGeometry.new())
	var carry := _carry(state)
	carry.lift(CarriedPiece.new(_unplaced(_stool()), Vector2i.ZERO), Vector2i.ZERO)
	carry.rotate_once()
	carry.rotate_once()
	assert_true(carry.place())
	carry.lift(CarriedPiece.new(_unplaced(_stool()), Vector2i.ZERO), Vector2i(1, 0))
	assert_eq(carry.orientation, 2)


func test_a_piece_lifted_from_the_board_keeps_its_own_orientation() -> void:
	var state := RealmState.new(RealmGeometry.new())
	var origin := BoardPlacement.new(_stool(), 5, [Vector2i.ZERO] as Array[Vector2i])
	state.place(origin)
	var carry := _carry(state)
	carry.lift(CarriedPiece.new(origin, Vector2i.ZERO), Vector2i.ZERO)
	assert_eq(carry.orientation, 5)


# One carry-path test per piece type, so the player's own route to the board is pinned for all
# three rather than just furniture: everything above this line carries furniture.
# https://github.com/snackpackgames/cosmicparade/issues/130
func test_a_shrine_carried_from_stock_lands_as_something_the_board_sees() -> void:
	# https://github.com/snackpackgames/cosmicparade/pull/96 -- the defect this pins: a shrine
	# placed through the carry was invisible to the board, and every test passed. Asserted
	# through a board-level query rather than against the placement just built, and through
	# `place()` rather than `commit()`, so the verdict gate is part of what is pinned.
	# https://github.com/snackpackgames/cosmicparade/issues/74
	var state := RealmState.new(RealmGeometry.new())
	var carry := _carry(state)
	carry.lift(CarriedPiece.new(_unplaced(_shrine()), Vector2i.ZERO), Vector2i(1, 0))
	assert_true(carry.place(), "the bare origin ring allows it, so the rest asserts something")
	assert_eq(state.vessel_placements().size(), 1, "the board sees a vessel standing")
	assert_eq(state.shrines_in_stock(), RealmState.STARTING_SHRINE_CAPACITY - 1)


func test_the_altar_relocated_through_the_carry_is_still_the_altar_the_board_reads() -> void:
	# The Altar's only carry is relocation: there is no Altar stock entry.
	# https://github.com/snackpackgames/cosmicparade/issues/130
	# Its authored `LevelFootprintCriterion` passes anywhere sited on a board carrying no zones,
	# and the Altar projects none of its own, so the triangle clears the core at (-2, 0).
	var piece := _altar()
	var state := RealmState.new(RealmGeometry.new())
	state.place_altar(piece)
	var carry := _carry(state)
	carry.lift(CarriedPiece.new(state.occupant_at(Vector2i.ZERO), piece.anchor), Vector2i.ZERO)
	carry.aim(Vector2i(-2, 0))
	assert_true(carry.place(), "the level footprint allows it, so the rest asserts something")
	var moved := Footprint.occupied(piece.shape, 0, Vector2i(-2, 0), piece.anchor)
	assert_eq(state.altar_hexes(), moved, "derived, so it cannot be stale")
	assert_false(state.altar_hexes().is_empty())
	# https://github.com/snackpackgames/cosmicparade/pull/102 -- a stored footprint went stale
	# here once, and still answered with the hexes the Altar had left.
	assert_false(state.altar_hexes().has(Vector2i.ZERO), "and not from where it stood")
