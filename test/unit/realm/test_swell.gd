extends GutTest


func _fruit(domain: Domain.Kind) -> Fruit:
	var fruit := Fruit.new()
	fruit.fruit_name = "test fruit"
	fruit.domain = domain
	return fruit


func _shrine() -> Shrine:
	var shrine := Shrine.new()
	shrine.piece_name = "test shrine"
	return shrine


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


func _place_shrine(state: RealmState, hex: Vector2i, domain: Domain.Kind) -> ShrinePlacement:
	var placement := ShrinePlacement.new(_shrine(), 0, [hex] as Array[Vector2i])
	placement.offering = _fruit(domain)
	state.place(placement)
	return placement


func _swell(adherents: int) -> Array:
	var state := _state()
	var balance := AdherentBalance.new()
	balance.grant(adherents)
	return [Swell.new(state, balance), state, balance]


func test_the_first_swell_costs_ten_and_is_readable_before_it_is_taken() -> void:
	var parts := _swell(0)
	assert_eq((parts[0] as Swell).cost_for_next(), 10)
	assert_false((parts[0] as Swell).can_afford())


func test_a_ring_swell_grows_the_board_raises_capacity_and_debits() -> void:
	var parts := _swell(10)
	var swell: Swell = parts[0]
	var state: RealmState = parts[1]
	assert_eq((swell.take_ring() as Array).size(), 24)
	assert_eq(state.geometry.hexes().size(), 61)
	assert_eq(state.shrine_capacity, 3)
	assert_eq((parts[2] as AdherentBalance).adherents, 0)
	assert_eq(swell.tiers_taken, 1)


func test_two_ring_swells_reach_ninety_one_hexes_and_capacity_four() -> void:
	var parts := _swell(30)
	var swell: Swell = parts[0]
	swell.take_ring()
	swell.take_ring()
	assert_eq((parts[1] as RealmState).geometry.hexes().size(), 91)
	assert_eq((parts[1] as RealmState).shrine_capacity, 4)
	assert_eq(swell.next_tier().board_effect, SwellTier.Effect.WING)


func test_an_unaffordable_swell_changes_nothing() -> void:
	# Review Focus 2. https://github.com/snackpackgames/cosmicparade/issues/76 — the
	# balance is debited only after the board has actually changed.
	var parts := _swell(9)
	assert_true((parts[0] as Swell).take_ring().is_empty())
	assert_eq((parts[1] as RealmState).geometry.hexes().size(), 37)
	assert_eq((parts[1] as RealmState).shrine_capacity, 2)
	assert_eq((parts[2] as AdherentBalance).adherents, 9)
	assert_eq((parts[0] as Swell).tiers_taken, 0)


func test_a_ring_swell_past_the_ceiling_debits_nothing() -> void:
	# Review Focus 2. RealmGeometry.swell() returns [] past radius 5; the balance must
	# not move when the board did not.
	var parts := _swell(1000)
	var swell: Swell = parts[0]
	swell.take_ring()
	swell.take_ring()
	var before: int = (parts[2] as AdherentBalance).adherents
	assert_true(swell.take_ring().is_empty())
	assert_eq((parts[2] as AdherentBalance).adherents, before)


func test_a_ring_swell_that_the_geometry_refuses_debits_nothing() -> void:
	# The tier says RING but the core is already at the ceiling.
	var parts := _swell(1000)
	var swell: Swell = parts[0]
	(parts[1] as RealmState).geometry.core_radius = RealmGeometry.CORE_MAX_RADIUS
	assert_true(swell.take_ring().is_empty())
	assert_eq((parts[2] as AdherentBalance).adherents, 1000)
	assert_eq(swell.tiers_taken, 0)
	assert_eq((parts[1] as RealmState).shrine_capacity, 2)


func test_swell_is_unavailable_past_the_sixth() -> void:
	var parts := _swell(0)
	var swell: Swell = parts[0]
	swell.tiers_taken = 6
	assert_false(swell.is_available())
	assert_null(swell.next_tier())
	assert_false(swell.can_afford())


func test_four_shrines_reach_depth_three_and_furniture_takes_it_to_four() -> void:
	# Review Focus 4. https://github.com/snackpackgames/cosmicparade/issues/80 — capacity
	# caps at 4 and depth needs five same-domain zones, so the elevation ceiling now
	# requires both halves of the realm.
	var state := _state()
	for hex: Vector2i in [Vector2i(-2, 0), Vector2i(-2, 1), Vector2i(-1, -1), Vector2i(-1, 0)]:
		_place_shrine(state, hex, Domain.Kind.FOREST)
	assert_eq(Elevation.depth_at(Vector2i.ZERO, state.zones()), 3)

	var hexes: Array[Vector2i] = [Vector2i(0, 1)]
	state.place(BoardPlacement.new(_piece(Domain.Kind.FOREST, 1), 0, hexes))

	assert_eq(Elevation.depth_at(Vector2i.ZERO, state.zones()), 4)


func test_a_wing_tier_is_takeable_only_once_the_rings_are_done() -> void:
	var parts := _swell(1000)
	var swell: Swell = parts[0]
	assert_false(swell.can_take_wing())
	swell.take_ring()
	swell.take_ring()
	assert_true(swell.can_take_wing())
	assert_eq(swell.cost_for_next(), 40)


func test_an_unaffordable_wing_never_begins() -> void:
	var parts := _swell(30)
	var swell: Swell = parts[0]
	swell.take_ring()
	swell.take_ring()
	assert_false(swell.can_take_wing())


func test_completing_a_wing_debits_and_advances_the_tier() -> void:
	var parts := _swell(70)
	var swell: Swell = parts[0]
	swell.take_ring()
	swell.take_ring()
	assert_true(swell.complete_wing())
	assert_eq((parts[2] as AdherentBalance).adherents, 0)
	assert_eq(swell.tiers_taken, 3)
	assert_eq(swell.cost_for_next(), 70)


func test_completing_a_wing_the_player_cannot_afford_changes_nothing() -> void:
	# The order from https://github.com/snackpackgames/cosmicparade/issues/76 runs forwards
	# only: the payment is never taken on credit.
	var parts := _swell(30)
	var swell: Swell = parts[0]
	swell.take_ring()
	swell.take_ring()
	assert_false(swell.complete_wing())
	assert_eq(swell.tiers_taken, 2)
