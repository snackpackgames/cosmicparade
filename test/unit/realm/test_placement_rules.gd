extends GutTest
## The verdict on a target: siting first, then every criterion on every hex.


func _state() -> RealmState:
	return RealmState.new(RealmGeometry.new())


func _stool() -> Furniture:
	return load("res://data/realm/furniture/mushroom_stool.tres")


func _bench() -> Furniture:
	return load("res://data/realm/furniture/fern_bench.tres")


func _stool_at(hex: Vector2i) -> BoardPlacement:
	return BoardPlacement.new(_stool(), 0, [hex] as Array[Vector2i])


# A placeable awaiting a target: no hexes, because it stands nowhere yet.
func _unplaced(piece: BoardPiece) -> BoardPlacement:
	return BoardPlacement.new(piece, 0, [] as Array[Vector2i])


# Two Forest stools whose radius-1 discs together cover the line (-1,0) (0,0) (1,0),
# which is what a straight-three authoring Forest >= 2 needs. One stool cannot do it:
# the only straight-three inside a radius-1 disc runs through the disc's own centre,
# and that hex is occupied by the piece projecting it.
func _flank_the_centre_line_with_forest(state: RealmState) -> void:
	state.place(_stool_at(Vector2i(-1, 1)))
	state.place(_stool_at(Vector2i(1, 1)))


func test_an_unencumbered_piece_is_allowed_on_an_empty_board() -> void:
	var verdict := PlacementRules.verdict(
		_unplaced(_stool()), 0, Vector2i.ZERO, Vector2i.ZERO, _state()
	)
	assert_true(verdict.allowed)
	assert_eq(verdict.failing_hexes, [] as Array[Vector2i])
	assert_eq(verdict.failing_criteria, [] as Array[PlacementCriterion])


# Review Focus 1: occupied hexes are board hexes by definition.
func test_a_footprint_hanging_off_the_board_is_refused() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/59
	var verdict := PlacementRules.verdict(
		_unplaced(_bench()), 0, Vector2i(3, 0), Vector2i(1, 0), _state()
	)
	assert_false(verdict.allowed)
	assert_true(verdict.failing_hexes.has(Vector2i(4, 0)), "the hex in the void is marked")
	assert_eq(
		verdict.failing_criteria, [] as Array[PlacementCriterion],
		"no criterion is named for a siting failure"
	)


func test_a_footprint_overlapping_another_piece_is_refused() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/51 — footprints never overlap.
	var state := _state()
	state.place(_stool_at(Vector2i.ZERO))
	var verdict := PlacementRules.verdict(_unplaced(_stool()), 0, Vector2i.ZERO, Vector2i.ZERO, state)
	assert_false(verdict.allowed)
	assert_eq(verdict.failing_hexes, [Vector2i.ZERO] as Array[Vector2i])


func test_influence_may_overlap_even_though_footprints_may_not() -> void:
	var state := _state()
	state.place(_stool_at(Vector2i.ZERO))
	assert_true(
		PlacementRules.verdict(_unplaced(_stool()), 0, Vector2i(1, 0), Vector2i.ZERO, state).allowed
	)


func test_a_failing_criterion_is_named_and_its_hexes_are_marked() -> void:
	# fern_bench authors Forest >= 2, which an empty board cannot satisfy.
	var verdict := PlacementRules.verdict(
		_unplaced(_bench()), 0, Vector2i.ZERO, Vector2i(1, 0), _state()
	)
	assert_false(verdict.allowed)
	assert_eq(verdict.failing_hexes.size(), 3, "every hex of the footprint is short")
	assert_eq(verdict.failing_criteria.size(), 1)
	assert_eq(verdict.failing_criteria[0].describe(), "Forest >= 2")


func test_a_criterion_reads_the_board_as_it_will_be_with_the_piece_on_it() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/41 — two flanking
	# Forest stools plus the bench's own zone make Forest >= 2 on all three hexes,
	# and all three sit at depth 1, so level footprint passes too.
	var state := _state()
	_flank_the_centre_line_with_forest(state)
	assert_true(
		PlacementRules.verdict(_unplaced(_bench()), 0, Vector2i.ZERO, Vector2i(1, 0), state).allowed
	)


func test_rotation_is_a_second_axis_of_escape_from_a_refusal() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/56 — turning changes
	# the occupied set, so one orientation can be refused and another allowed.
	var state := _state()
	state.place(_stool_at(Vector2i(2, 0)))
	var blocked := PlacementRules.verdict(
		_unplaced(_bench()), 0, Vector2i(1, 0), Vector2i(1, 0), state
	)
	var turned := PlacementRules.verdict(
		_unplaced(_bench()), 1, Vector2i(1, 0), Vector2i(1, 0), state
	)
	assert_false(blocked.allowed, "straight along the row it collides")
	assert_false(turned.failing_hexes.has(Vector2i(2, 0)), "turned, it clears the stool")


func test_several_failing_criteria_are_all_named_at_once() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/62 — never one at a time.
	var piece := Furniture.new()
	piece.shape = Footprint.Shape.PAIR
	var projection := DomainProjection.new()
	projection.domain = Domain.Kind.GALE
	projection.reach = 1
	piece.zone_source = projection
	var influence := DomainInfluenceCriterion.new()
	influence.domain = Domain.Kind.FLAME
	influence.minimum = 1
	var height := HeightCriterion.new()
	height.min_depth = 2
	piece.criteria = [influence, height] as Array[PlacementCriterion]
	var verdict := PlacementRules.verdict(_unplaced(piece), 0, Vector2i.ZERO, Vector2i.ZERO, _state())
	assert_eq(verdict.failing_criteria.size(), 2)
