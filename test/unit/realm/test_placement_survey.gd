extends GutTest
## One sweep over the board: is the piece placeable at all, and which requirements nothing meets.


func _stool() -> Furniture:
	return load("res://data/realm/furniture/mushroom_stool.tres")


func _bench() -> Furniture:
	return load("res://data/realm/furniture/fern_bench.tres")


func _stool_at(hex: Vector2i) -> FurniturePlacement:
	return FurniturePlacement.new(_stool(), 0, [hex] as Array[Vector2i])


func _piece(criteria: Array[PlacementCriterion]) -> Furniture:
	var piece := Furniture.new()
	piece.shape = Footprint.Shape.SINGLE
	piece.domain = Domain.Kind.FOREST
	piece.zone_radius = 1
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
	# https://github.com/snackpackgames/cosmicparade/issues/62
	var survey := PlacementRules.survey(
		_piece([_forest_two()] as Array[PlacementCriterion]), Vector2i.ZERO,
		RealmState.new(RealmGeometry.new())
	)
	assert_false(survey.placeable)
	assert_eq(survey.unsatisfiable.size(), 1)
	assert_eq(survey.unsatisfiable[0].describe(), "Forest >= 2")


func test_every_individually_unsatisfiable_requirement_is_named_not_just_the_first() -> void:
	var other := DomainInfluenceCriterion.new()
	other.domain = Domain.Kind.GALE
	other.minimum = 3
	var survey := PlacementRules.survey(
		_piece([_forest_two(), other] as Array[PlacementCriterion]), Vector2i.ZERO,
		RealmState.new(RealmGeometry.new())
	)
	assert_eq(survey.unsatisfiable.size(), 2, "the whole errand, not its first leg")


func test_a_satisfiable_requirement_is_not_named() -> void:
	var state := RealmState.new(RealmGeometry.new())
	state.place(_stool_at(Vector2i.ZERO))
	var survey := PlacementRules.survey(
		_piece([_forest_two()] as Array[PlacementCriterion]), Vector2i.ZERO, state
	)
	assert_true(survey.placeable, "a Forest neighbour plus its own zone makes Forest >= 2")
	assert_eq(survey.unsatisfiable, [])


func test_requirements_satisfiable_apart_but_not_together_name_nothing() -> void:
	# placeable == false with an empty list is a real state under AND, and it is
	# not the "nothing on your realm has..." message.
	var state := RealmState.new(RealmGeometry.new())
	state.place(_stool_at(Vector2i.ZERO))
	var position := BoardPositionCriterion.new()
	var survey := PlacementRules.survey(
		_piece([_forest_two(), position] as Array[PlacementCriterion]), Vector2i.ZERO, state
	)
	assert_false(survey.placeable, "the stool's reach never touches the rim")
	assert_eq(survey.unsatisfiable, [], "each one passes somewhere, just not together")


func test_the_sweep_considers_every_hex_and_every_orientation() -> void:
	var state := RealmState.new(RealmGeometry.new())
	state.place(_stool_at(Vector2i(-1, 1)))
	state.place(_stool_at(Vector2i(1, 1)))
	assert_true(PlacementRules.survey(_bench(), Vector2i(1, 0), state).placeable)
