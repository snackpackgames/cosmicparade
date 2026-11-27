extends GutTest
## What the Altar reads: shrines only, each counted once, per domain.


func _fruit(domain: Domain.Kind) -> Fruit:
	var fruit := Fruit.new()
	fruit.fruit_name = "test fruit"
	fruit.domain = domain
	return fruit


func _shrine() -> Shrine:
	var shrine := Shrine.new()
	shrine.piece_name = "test shrine"
	shrine.zone_source = OfferingVessel.new()
	return shrine


func _altar() -> Altar:
	var altar := Altar.new()
	altar.piece_name = "test altar"
	altar.reading = InfluenceReading.new()
	altar.shape = Footprint.Shape.TRIANGLE
	altar.criteria = [LevelFootprintCriterion.new()] as Array[PlacementCriterion]
	return altar


func _piece(domain: Domain.Kind, radius: int) -> Furniture:
	var piece := Furniture.new()
	piece.piece_name = "test piece"
	var projection := DomainProjection.new()
	projection.domain = domain
	projection.reach = radius
	piece.zone_source = projection
	piece.shape = Footprint.Shape.SINGLE
	return piece


func _state() -> RealmState:
	return RealmState.new(RealmGeometry.new())


func _place_shrine(state: RealmState, hex: Vector2i, domain: Domain.Kind) -> BoardPlacement:
	var placement := BoardPlacement.new(_shrine(), 0, [hex] as Array[Vector2i])
	placement.offer(_fruit(domain))
	state.place(placement)
	return placement


func test_a_shrine_covering_all_three_hexes_counts_once() -> void:
	# Review Focus 1. https://github.com/snackpackgames/cosmicparade/issues/79 — each
	# shrine once, on any hex, so the triangle-three is reach and not a multiplier.
	# (-1, 0) is distance 1, 2 and 2 from the Altar's three hexes.
	var state := _state()
	state.place_altar(_altar())
	_place_shrine(state, Vector2i(-1, 0), Domain.Kind.FOREST)
	assert_eq(state.altar_reading().count_for(Domain.Kind.FOREST), 1)


func test_a_shrine_reaching_only_one_hex_still_counts() -> void:
	var state := _state()
	state.place_altar(_altar())
	_place_shrine(state, Vector2i(3, -1), Domain.Kind.FOREST)
	assert_eq(state.altar_reading().count_for(Domain.Kind.FOREST), 1)


func test_the_reading_tallies_per_domain() -> void:
	var state := _state()
	state.place_altar(_altar())
	_place_shrine(state, Vector2i(-1, 0), Domain.Kind.FOREST)
	_place_shrine(state, Vector2i(-1, 1), Domain.Kind.FOREST)
	_place_shrine(state, Vector2i(2, 0), Domain.Kind.FLAME)
	assert_eq(state.altar_reading().count_for(Domain.Kind.FOREST), 2)
	assert_eq(state.altar_reading().count_for(Domain.Kind.FLAME), 1)
	assert_eq(state.altar_reading().domains_present().size(), 2)


func test_furniture_is_not_read() -> void:
	var state := _state()
	state.place_altar(_altar())
	state.place(
		BoardPlacement.new(_piece(Domain.Kind.FOREST, 2), 0, [Vector2i(-1, 0)] as Array[Vector2i])
	)
	assert_true(state.altar_reading().is_empty())


func test_a_lapsed_shrine_in_range_reads_as_nothing() -> void:
	var state := _state()
	state.place_altar(_altar())
	var shrine := _place_shrine(state, Vector2i(-1, 0), Domain.Kind.FOREST)
	shrine.empty_vessel()
	assert_true(state.altar_reading().is_empty())
	assert_eq(state.altar_reading().count_for(Domain.Kind.FOREST), 0)
