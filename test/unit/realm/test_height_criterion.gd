extends GutTest


func _context(zones: Array[InfluenceZone], occupied: Array[Vector2i]) -> PlacementContext:
	return PlacementContext.new(RealmState.new(RealmGeometry.new()), occupied, zones)


func _two_stone_zones() -> Array[InfluenceZone]:
	return [
		InfluenceZone.new(Domain.Kind.STONE, [Vector2i.ZERO]),
		InfluenceZone.new(Domain.Kind.STONE, [Vector2i.ZERO]),
	]


func test_a_minimum_depth_refuses_flat_ground() -> void:
	var criterion := HeightCriterion.new()
	criterion.min_depth = 1
	var context := _context([] as Array[InfluenceZone], [Vector2i.ZERO] as Array[Vector2i])
	assert_eq(criterion.failing_hexes(context), [Vector2i.ZERO] as Array[Vector2i])


func test_a_minimum_depth_passes_on_raised_ground() -> void:
	var criterion := HeightCriterion.new()
	criterion.min_depth = 1
	var context := _context(_two_stone_zones(), [Vector2i.ZERO] as Array[Vector2i])
	assert_eq(criterion.failing_hexes(context), [] as Array[Vector2i])


func test_a_maximum_depth_refuses_ground_that_is_too_high() -> void:
	var criterion := HeightCriterion.new()
	criterion.max_depth = 0
	var context := _context(_two_stone_zones(), [Vector2i.ZERO] as Array[Vector2i])
	assert_eq(criterion.failing_hexes(context), [Vector2i.ZERO] as Array[Vector2i])


func test_it_fails_only_the_hexes_that_are_wrong() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/55 — every criterion is
	# evaluated against every hex of the footprint.
	var criterion := HeightCriterion.new()
	criterion.min_depth = 1
	var context := _context(
		_two_stone_zones(), [Vector2i.ZERO, Vector2i(1, 0)] as Array[Vector2i]
	)
	assert_eq(criterion.failing_hexes(context), [Vector2i(1, 0)] as Array[Vector2i])


func test_the_default_range_passes_anything_the_rule_can_produce() -> void:
	assert_eq(HeightCriterion.new().min_depth, 0)
	assert_eq(HeightCriterion.new().max_depth, Elevation.MAX_DEPTH)


func test_it_describes_itself_without_naming_a_hex() -> void:
	var criterion := HeightCriterion.new()
	criterion.min_depth = 2
	assert_string_contains(criterion.describe(), "2")
