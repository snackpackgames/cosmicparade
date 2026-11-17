extends GutTest
## A shrine standing on the board, and what its vessel makes it project.


func _fruit(domain: Domain.Kind) -> Fruit:
	var fruit := Fruit.new()
	fruit.fruit_name = "test fruit"
	fruit.domain = domain
	return fruit


func _shrine() -> Shrine:
	var shrine := Shrine.new()
	shrine.piece_name = "test shrine"
	return shrine


func test_an_empty_vessel_projects_nothing_at_all() -> void:
	var placement := ShrinePlacement.new(_shrine(), 0, [Vector2i.ZERO] as Array[Vector2i])
	assert_null(placement.zone())


func test_a_fed_vessel_projects_the_offerings_domain_at_radius_two() -> void:
	var placement := ShrinePlacement.new(_shrine(), 0, [Vector2i.ZERO] as Array[Vector2i])
	placement.offering = _fruit(Domain.Kind.WETLAND)
	assert_eq(placement.zone().domain, Domain.Kind.WETLAND)
	assert_eq(placement.zone().hex_count(), 19)


func test_the_radius_does_not_change_with_what_is_offered() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/55 — nothing modifies what a
	# piece projects.
	var placement := ShrinePlacement.new(_shrine(), 0, [Vector2i.ZERO] as Array[Vector2i])
	for domain: Domain.Kind in [Domain.Kind.FOREST, Domain.Kind.FLAME, Domain.Kind.GALE]:
		placement.offering = _fruit(domain)
		assert_eq(placement.zone().hex_count(), 19)


func test_a_shrine_placement_is_a_board_placement() -> void:
	# One occupancy index over all three kinds of board piece.
	# https://github.com/snackpackgames/cosmicparade/issues/51
	var placement := ShrinePlacement.new(_shrine(), 0, [Vector2i.ZERO] as Array[Vector2i])
	assert_true(placement is BoardPlacement)
