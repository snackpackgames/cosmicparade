extends GutTest
## One sweep: is the piece placeable anywhere, and which requirements does nothing satisfy.


func _stool() -> Furniture:
	return load("res://data/realm/furniture/mushroom_stool.tres")


func _bench() -> Furniture:
	return load("res://data/realm/furniture/fern_bench.tres")


func _stool_at(hex: Vector2i) -> BoardPlacement:
	return BoardPlacement.new(_stool(), 0, [hex] as Array[Vector2i])


func _flank_the_centre_line_with_forest(state: RealmState) -> void:
	state.place(_stool_at(Vector2i(-1, 1)))
	state.place(_stool_at(Vector2i(1, 1)))


func _piece(criteria: Array[PlacementCriterion]) -> Furniture:
	var piece := Furniture.new()
	piece.shape = Footprint.Shape.SINGLE
	var projection := DomainProjection.new()
	projection.domain = Domain.Kind.GALE
	projection.reach = 1
	piece.zone_source = projection
	piece.criteria = criteria
	return piece


func _forest_two() -> DomainInfluenceCriterion:
	var influence := DomainInfluenceCriterion.new()
	influence.domain = Domain.Kind.FOREST
	influence.minimum = 2
	return influence


func test_an_unencumbered_piece_is_placeable_on_an_empty_board() -> void:
	var survey := PlacementRules.survey(
		_piece([] as Array[PlacementCriterion]), Vector2i.ZERO,
		RealmState.new(RealmGeometry.new())
	)
	assert_true(survey.placeable)
	assert_eq(survey.unsatisfiable, [])


func test_a_requirement_nothing_satisfies_is_named() -> void:
	var survey := PlacementRules.survey(
		_piece([_forest_two()] as Array[PlacementCriterion]), Vector2i.ZERO,
		RealmState.new(RealmGeometry.new())
	)
	assert_false(survey.placeable)
	assert_eq(survey.unsatisfiable.size(), 1)
	assert_eq(survey.unsatisfiable[0].describe(), "Forest >= 2")


func test_every_individually_unsatisfiable_requirement_is_named_not_just_the_first() -> void:
	var height := HeightCriterion.new()
	height.min_depth = 1
	var survey := PlacementRules.survey(
		_piece([_forest_two(), height] as Array[PlacementCriterion]), Vector2i.ZERO,
		RealmState.new(RealmGeometry.new())
	)
	assert_eq(survey.unsatisfiable.size(), 2, "the whole errand, not its first leg")


func test_a_satisfiable_requirement_is_not_named() -> void:
	var state := RealmState.new(RealmGeometry.new())
	_flank_the_centre_line_with_forest(state)
	var survey := PlacementRules.survey(
		_piece([_forest_two()] as Array[PlacementCriterion]), Vector2i.ZERO, state
	)
	assert_true(survey.placeable)
	assert_eq(survey.unsatisfiable, [])


func test_requirements_satisfiable_apart_but_not_together_name_nothing() -> void:
	var state := RealmState.new(RealmGeometry.new())
	_flank_the_centre_line_with_forest(state)
	var position := BoardPositionCriterion.new()
	position.require_edge = true
	var survey := PlacementRules.survey(
		_piece([_forest_two(), position] as Array[PlacementCriterion]), Vector2i.ZERO, state
	)
	assert_false(survey.placeable, "the stools' reach never touches the rim")
	assert_eq(survey.unsatisfiable, [], "each one passes somewhere, just not together")


func test_the_sweep_considers_every_hex_and_every_orientation() -> void:
	var state := RealmState.new(RealmGeometry.new())
	_flank_the_centre_line_with_forest(state)
	assert_true(PlacementRules.survey(_bench(), Vector2i(1, 0), state).placeable)
