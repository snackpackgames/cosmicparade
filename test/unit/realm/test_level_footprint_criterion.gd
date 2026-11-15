extends GutTest


func _context(occupied: Array[Vector2i], zones: Array[InfluenceZone]) -> PlacementContext:
	return PlacementContext.new(RealmState.new(RealmGeometry.new()), occupied, zones)


func test_a_single_hex_footprint_is_always_level() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/55 — only meaningful at size >= 2.
	assert_eq(
		LevelFootprintCriterion.new().failing_hexes(
			_context([Vector2i.ZERO] as Array[Vector2i], [] as Array[InfluenceZone])
		),
		[] as Array[Vector2i]
	)


func test_a_footprint_on_flat_ground_is_level() -> void:
	var occupied: Array[Vector2i] = [Vector2i.ZERO, Vector2i(1, 0), Vector2i(2, 0)]
	assert_eq(
		LevelFootprintCriterion.new().failing_hexes(
			_context(occupied, [] as Array[InfluenceZone])
		),
		[] as Array[Vector2i]
	)


func test_a_footprint_crossing_a_step_fails_on_its_whole_footprint() -> void:
	# The criterion is a property of the footprint as a whole and belongs to no
	# single hex: https://github.com/snackpackgames/cosmicparade/issues/62
	var occupied: Array[Vector2i] = [Vector2i.ZERO, Vector2i(1, 0)]
	var zones: Array[InfluenceZone] = [
		InfluenceZone.new(Domain.Kind.STONE, [Vector2i.ZERO]),
		InfluenceZone.new(Domain.Kind.STONE, [Vector2i.ZERO]),
	]
	assert_eq(
		LevelFootprintCriterion.new().failing_hexes(_context(occupied, zones)).size(), 2
	)
