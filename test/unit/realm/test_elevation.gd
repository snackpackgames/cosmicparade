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
