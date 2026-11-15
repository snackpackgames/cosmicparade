extends GutTest


func _context(zones: Array[InfluenceZone], occupied: Array[Vector2i]) -> PlacementContext:
	return PlacementContext.new(RealmState.new(RealmGeometry.new()), occupied, zones)


func _forest_at_least(minimum: int) -> DomainInfluenceCriterion:
	var criterion := DomainInfluenceCriterion.new()
	criterion.domain = Domain.Kind.FOREST
	criterion.minimum = minimum
	return criterion


func test_a_minimum_of_two_refuses_a_hex_the_piece_only_covers_itself() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/55 — Forest >= 2 is
	# "a Forest neighbour", because the piece's own zone is one of the two.
	var own: Array[InfluenceZone] = [InfluenceZone.new(Domain.Kind.FOREST, [Vector2i.ZERO])]
	var context := _context(own, [Vector2i.ZERO] as Array[Vector2i])
	assert_eq(_forest_at_least(2).failing_hexes(context), [Vector2i.ZERO] as Array[Vector2i])


func test_a_second_zone_of_the_same_domain_satisfies_it() -> void:
	var zones: Array[InfluenceZone] = [
		InfluenceZone.new(Domain.Kind.FOREST, [Vector2i.ZERO]),
		InfluenceZone.new(Domain.Kind.FOREST, [Vector2i.ZERO]),
	]
	var context := _context(zones, [Vector2i.ZERO] as Array[Vector2i])
	assert_eq(_forest_at_least(2).failing_hexes(context), [] as Array[Vector2i])


func test_another_domain_does_not_count() -> void:
	var zones: Array[InfluenceZone] = [InfluenceZone.new(Domain.Kind.STONE, [Vector2i.ZERO])]
	var context := _context(zones, [Vector2i.ZERO] as Array[Vector2i])
	assert_eq(_forest_at_least(1).failing_hexes(context).size(), 1)


func test_it_must_hold_on_every_hex_of_the_footprint() -> void:
	var zones: Array[InfluenceZone] = [InfluenceZone.new(Domain.Kind.FOREST, [Vector2i.ZERO])]
	var context := _context(zones, [Vector2i.ZERO, Vector2i(1, 0)] as Array[Vector2i])
	assert_eq(_forest_at_least(1).failing_hexes(context), [Vector2i(1, 0)] as Array[Vector2i])


func test_it_describes_itself_as_the_player_reads_it() -> void:
	assert_eq(_forest_at_least(2).describe(), "Forest >= 2")
