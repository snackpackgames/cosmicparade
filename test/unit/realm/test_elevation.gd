extends GutTest
## The elevation rule: depth per domain, maximum across domains, height from depth.

func _zones(domain: Domain.Kind, count: int, hex: Vector2i) -> Array[InfluenceZone]:
	var zones: Array[InfluenceZone] = []
	for _i in count:
		zones.append(InfluenceZone.new(domain, [hex]))
	return zones


func test_a_hex_with_no_influence_is_flat() -> void:
	var none: Array[InfluenceZone] = []
	assert_eq(Elevation.depth_at(Vector2i.ZERO, none), 0)


# The off-by-one: burgeon is the same domain overlapping itself, so one zone
# raises nothing. https://github.com/snackpackgames/cosmicparade/issues/37
func test_a_single_zone_leaves_its_hex_flat() -> void:
	assert_eq(Elevation.depth_at(Vector2i.ZERO, _zones(Domain.Kind.STONE, 1, Vector2i.ZERO)), 0)


func test_two_zones_of_one_domain_raise_the_hex_one_level() -> void:
	assert_eq(Elevation.depth_at(Vector2i.ZERO, _zones(Domain.Kind.STONE, 2, Vector2i.ZERO)), 1)


func test_depth_is_one_less_than_the_zones_covering_the_hex() -> void:
	assert_eq(Elevation.depth_at(Vector2i.ZERO, _zones(Domain.Kind.FOREST, 4, Vector2i.ZERO)), 3)


# Review Focus 5: the cap boundary. https://github.com/snackpackgames/cosmicparade/issues/29
func test_five_zones_of_one_domain_reach_the_ceiling() -> void:
	assert_eq(Elevation.depth_at(Vector2i.ZERO, _zones(Domain.Kind.GALE, 5, Vector2i.ZERO)), 4)


func test_a_sixth_zone_adds_nothing() -> void:
	assert_eq(Elevation.depth_at(Vector2i.ZERO, _zones(Domain.Kind.GALE, 6, Vector2i.ZERO)), 4)


# The maximum, not the sum. https://github.com/snackpackgames/cosmicparade/issues/40
func test_the_strongest_single_domain_sets_the_depth() -> void:
	var zones := _zones(Domain.Kind.STONE, 4, Vector2i.ZERO)
	zones.append_array(_zones(Domain.Kind.WETLAND, 2, Vector2i.ZERO))
	assert_eq(Elevation.depth_at(Vector2i.ZERO, zones), 3)


func test_two_maxed_domains_still_cap_at_four() -> void:
	var zones := _zones(Domain.Kind.STONE, 5, Vector2i.ZERO)
	zones.append_array(_zones(Domain.Kind.WETLAND, 5, Vector2i.ZERO))
	assert_eq(Elevation.depth_at(Vector2i.ZERO, zones), 4)


func test_mixing_domains_buys_no_height() -> void:
	var zones := _zones(Domain.Kind.FLAME, 1, Vector2i.ZERO)
	zones.append_array(_zones(Domain.Kind.GALE, 1, Vector2i.ZERO))
	assert_eq(Elevation.depth_at(Vector2i.ZERO, zones), 0)


# One rule for all six domains: no per-domain step, ceiling or branch.
# https://github.com/snackpackgames/cosmicparade/issues/32
func test_every_domain_raises_ground_identically() -> void:
	for domain: int in Domain.Kind.values():
		assert_eq(
			Elevation.depth_at(Vector2i.ZERO, _zones(domain, 3, Vector2i.ZERO)),
			2,
			"domain %d should raise like every other" % domain
		)


# Review Focus 4: a zone that covers nothing on the hex under test.
func test_a_zone_elsewhere_does_not_raise_this_hex() -> void:
	assert_eq(Elevation.depth_at(Vector2i.ZERO, _zones(Domain.Kind.STONE, 3, Vector2i(9, -4))), 0)


func test_a_flat_hex_is_at_board_level() -> void:
	assert_almost_eq(Elevation.height_for_depth(0), 0.0, 0.0001)


func test_one_level_is_the_step_ratio_of_the_circumradius() -> void:
	assert_almost_eq(
		Elevation.height_for_depth(1), 0.35 * HexCoordinates.CIRCUMRADIUS, 0.0001
	)


func test_the_ceiling_is_one_point_four_circumradii() -> void:
	assert_almost_eq(
		Elevation.height_for_depth(Elevation.MAX_DEPTH), 1.40 * HexCoordinates.CIRCUMRADIUS, 0.0001
	)


func test_every_level_is_the_same_height_as_every_other() -> void:
	# Uniform, not diminishing: a drop's size has to tell you its depth.
	# https://github.com/snackpackgames/cosmicparade/issues/29
	for depth in range(1, Elevation.MAX_DEPTH + 1):
		var rise := Elevation.height_for_depth(depth) - Elevation.height_for_depth(depth - 1)
		assert_almost_eq(rise, 0.35 * HexCoordinates.CIRCUMRADIUS, 0.0001)


func test_height_at_reads_the_arrangement() -> void:
	assert_almost_eq(
		Elevation.height_at(Vector2i.ZERO, _zones(Domain.Kind.STONE, 3, Vector2i.ZERO)),
		2.0 * 0.35 * HexCoordinates.CIRCUMRADIUS,
		0.0001
	)


func test_evaluating_an_arrangement_does_not_change_anything() -> void:
	# Derived, no cache, no stored height: calling twice with a different
	# arrangement in between must not carry anything over.
	# https://github.com/snackpackgames/cosmicparade/issues/33
	var raised := _zones(Domain.Kind.STONE, 3, Vector2i.ZERO)
	var none: Array[InfluenceZone] = []
	assert_gt(Elevation.height_at(Vector2i.ZERO, raised), 0.0)
	assert_almost_eq(Elevation.height_at(Vector2i.ZERO, none), 0.0, 0.0001)
	assert_gt(Elevation.height_at(Vector2i.ZERO, raised), 0.0)
