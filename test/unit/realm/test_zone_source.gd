extends GutTest
## The component base: every default is what an override replaces.


func test_the_base_projects_nothing() -> void:
	assert_null(ZoneSource.new().zone_over([Vector2i.ZERO] as Array[Vector2i]))


func test_the_base_is_shared_rather_than_copied() -> void:
	var source := ZoneSource.new()
	assert_eq(source.for_placement(), source)


func test_the_base_answers_no_to_every_vessel_question() -> void:
	var source := ZoneSource.new()
	assert_false(source.can_hold_offering())
	assert_false(source.holds_offering())
	source.accept_offering(null)
	source.empty_vessel()
	assert_false(source.holds_offering())
