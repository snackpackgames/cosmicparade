extends GutTest
## A single influence zone: one domain over a set of hexes.

func test_a_zone_covers_the_hexes_it_was_given() -> void:
	var zone := InfluenceZone.new(Domain.Kind.STONE, [Vector2i.ZERO, Vector2i(1, 0)])
	assert_true(zone.covers(Vector2i.ZERO))
	assert_true(zone.covers(Vector2i(1, 0)))


func test_a_zone_does_not_cover_a_hex_outside_it() -> void:
	var zone := InfluenceZone.new(Domain.Kind.STONE, [Vector2i.ZERO])
	assert_false(zone.covers(Vector2i(5, -5)))


func test_an_empty_zone_covers_nothing() -> void:
	assert_false(InfluenceZone.new(Domain.Kind.GALE, []).covers(Vector2i.ZERO))


func test_a_zone_keeps_its_domain() -> void:
	assert_eq(InfluenceZone.new(Domain.Kind.WETLAND, []).domain, Domain.Kind.WETLAND)


# Review Focus 2: influence is a set. A hex listed twice is covered once,
# or the zone would contribute two levels of depth on its own.
func test_a_hex_listed_twice_is_covered_once() -> void:
	var zone := InfluenceZone.new(Domain.Kind.FLAME, [Vector2i.ZERO, Vector2i.ZERO])
	assert_true(zone.covers(Vector2i.ZERO))
	assert_eq(zone.hex_count(), 1)
