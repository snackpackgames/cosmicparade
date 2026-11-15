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


func test_a_single_hex_piece_projects_a_seven_hex_disc() -> void:
	var zone := InfluenceZone.project(
		Domain.Kind.FOREST, [Vector2i.ZERO] as Array[Vector2i], 1
	)
	assert_eq(zone.hex_count(), 7)
	assert_true(zone.covers(Vector2i.ZERO), "a piece always stands inside its own influence")


func test_each_footprint_projects_its_derived_zone_size() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/52 — grown from every
	# occupied hex, so the five footprints are five zone shapes.
	var expected := {
		Footprint.Shape.SINGLE: 7, Footprint.Shape.PAIR: 10, Footprint.Shape.STRAIGHT: 13,
		Footprint.Shape.BEND: 13, Footprint.Shape.TRIANGLE: 12,
	}
	for shape: Footprint.Shape in expected:
		var occupied := Footprint.occupied(shape, 0, Vector2i.ZERO, Vector2i.ZERO)
		assert_eq(
			InfluenceZone.project(Domain.Kind.STONE, occupied, 1).hex_count(),
			expected[shape], "%s" % shape
		)


func test_radius_zero_influences_only_the_hexes_the_piece_stands_on() -> void:
	var occupied := Footprint.occupied(
		Footprint.Shape.PAIR, 0, Vector2i.ZERO, Vector2i.ZERO
	)
	assert_eq(InfluenceZone.project(Domain.Kind.GALE, occupied, 0).hex_count(), 2)


func test_a_zone_is_one_set_however_much_its_discs_overlap() -> void:
	var occupied := Footprint.occupied(
		Footprint.Shape.TRIANGLE, 0, Vector2i.ZERO, Vector2i.ZERO
	)
	var zone := InfluenceZone.project(Domain.Kind.FLAME, occupied, 1)
	assert_eq(zone.coordinates().size(), zone.hex_count())


func test_a_projected_zone_keeps_its_domain() -> void:
	assert_eq(
		InfluenceZone.project(Domain.Kind.WETLAND, [Vector2i.ZERO] as Array[Vector2i], 1).domain,
		Domain.Kind.WETLAND
	)


func test_a_zone_projects_into_the_void_rather_than_clipping() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/59 — a set of
	# coordinates, not of board hexes. project() takes no board at all.
	var zone := InfluenceZone.project(
		Domain.Kind.FOREST, [Vector2i(3, 0)] as Array[Vector2i], 1
	)
	assert_eq(zone.hex_count(), 7)
	assert_true(zone.covers(Vector2i(4, 0)), "one hex past the rim of a radius-3 board")


func test_coordinates_lists_every_hex_the_zone_covers() -> void:
	var zone := InfluenceZone.new(Domain.Kind.STONE, [Vector2i.ZERO, Vector2i(1, 0)])
	var coordinates := zone.coordinates()
	coordinates.sort()
	assert_eq(coordinates, [Vector2i.ZERO, Vector2i(1, 0)] as Array[Vector2i])
