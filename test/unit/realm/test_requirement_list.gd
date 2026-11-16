extends GutTest
## The piece's half of a refusal: its own requirement lines, the failing ones flagged.


func _forest_two() -> DomainInfluenceCriterion:
	var criterion := DomainInfluenceCriterion.new()
	criterion.domain = Domain.Kind.FOREST
	criterion.minimum = 2
	return criterion


func test_a_carried_piece_shows_its_own_requirements() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/62
	var list: RequirementList = add_child_autofree(RequirementList.new())
	list.show_requirements([_forest_two(), LevelFootprintCriterion.new()])
	assert_eq(list.lines(), ["Forest >= 2", LevelFootprintCriterion.new().describe()])
	assert_eq(list.failing_lines(), [], "nothing fails until a target does")


func test_marking_flags_only_the_requirements_that_failed() -> void:
	var list: RequirementList = add_child_autofree(RequirementList.new())
	var influence := _forest_two()
	list.show_requirements([influence, LevelFootprintCriterion.new()])
	list.mark_failing([influence])
	assert_eq(list.failing_lines(), ["Forest >= 2"])


func test_marking_an_empty_list_clears_every_flag() -> void:
	var list: RequirementList = add_child_autofree(RequirementList.new())
	var influence := _forest_two()
	list.show_requirements([influence])
	list.mark_failing([influence])
	list.mark_failing([])
	assert_eq(list.failing_lines(), [])


func test_a_piece_with_no_requirements_shows_an_empty_list() -> void:
	var list: RequirementList = add_child_autofree(RequirementList.new())
	list.show_requirements([])
	assert_eq(list.lines(), [])


func test_hiding_drops_the_lines() -> void:
	var list: RequirementList = add_child_autofree(RequirementList.new())
	list.show_requirements([_forest_two()])
	list.hide_requirements()
	assert_eq(list.lines(), [])
