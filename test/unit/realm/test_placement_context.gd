extends GutTest


func _context(occupied: Array[Vector2i], zones: Array[InfluenceZone]) -> PlacementContext:
	return PlacementContext.new(RealmState.new(RealmGeometry.new()), occupied, zones)


func test_the_context_reads_board_membership_from_the_geometry() -> void:
	var context := _context([Vector2i.ZERO] as Array[Vector2i], [] as Array[InfluenceZone])
	assert_true(context.has_hex(Vector2i(3, 0)))
	assert_false(context.has_hex(Vector2i(4, 0)))
	assert_true(context.is_edge_hex(Vector2i(3, 0)))


func test_depth_comes_from_the_zones_it_was_given() -> void:
	var zones: Array[InfluenceZone] = [
		InfluenceZone.new(Domain.Kind.FOREST, [Vector2i.ZERO]),
		InfluenceZone.new(Domain.Kind.FOREST, [Vector2i.ZERO]),
	]
	assert_eq(_context([Vector2i.ZERO] as Array[Vector2i], zones).depth_at(Vector2i.ZERO), 1)


func test_zone_count_counts_zones_of_one_domain_over_a_hex() -> void:
	var zones: Array[InfluenceZone] = [
		InfluenceZone.new(Domain.Kind.FOREST, [Vector2i.ZERO]),
		InfluenceZone.new(Domain.Kind.FOREST, [Vector2i.ZERO]),
		InfluenceZone.new(Domain.Kind.STONE, [Vector2i.ZERO]),
	]
	var context := _context([Vector2i.ZERO] as Array[Vector2i], zones)
	assert_eq(context.zone_count(Domain.Kind.FOREST, Vector2i.ZERO), 2)
	assert_eq(context.zone_count(Domain.Kind.STONE, Vector2i.ZERO), 1)
	assert_eq(context.zone_count(Domain.Kind.GALE, Vector2i.ZERO), 0)
