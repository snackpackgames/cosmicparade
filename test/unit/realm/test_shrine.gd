extends GutTest
## The authored shrine: one hex, no criteria, one radius for all.


func test_a_shrine_is_one_hex_with_no_criteria() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/74 — single-hex because every
	# multi-hex footprint at radius 2 projects 24-29 of 37 hexes; criteria-free because
	# the README says shrines are freely placed.
	var shrine: Shrine = load("res://data/realm/shrine/plain_shrine.tres")
	assert_eq(shrine.shape, Footprint.Shape.SINGLE)
	assert_eq(shrine.criteria.size(), 0)
	assert_eq(Shrine.ZONE_RADIUS, 2)
