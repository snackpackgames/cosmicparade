extends GutTest
## The closed vocabulary of five footprint shapes, and orientation about the grab hex.

const SIZES := {
	Footprint.Shape.SINGLE: 1,
	Footprint.Shape.PAIR: 2,
	Footprint.Shape.STRAIGHT: 3,
	Footprint.Shape.BEND: 3,
	Footprint.Shape.TRIANGLE: 3,
}


func _canonical(hexes: Array[Vector2i]) -> Array:
	var best: Array = []
	for anchor: Vector2i in hexes:
		var form: Array[Vector2i] = []
		for hex: Vector2i in hexes:
			form.append(hex - anchor)
		form.sort()
		if best.is_empty() or form < best:
			best = form
	return best


func test_the_vocabulary_is_five_shapes_and_no_more() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/51 — the complete set
	# of polyhexes up to size 3. A sixth entry is a design change, not a feature.
	assert_eq(Footprint.Shape.size(), 5)


func test_each_shape_has_its_decided_hex_count() -> void:
	for shape: Footprint.Shape in SIZES:
		assert_eq(Footprint.offsets_for(shape).size(), SIZES[shape])


func test_every_shape_is_edge_connected() -> void:
	for shape: Footprint.Shape in SIZES:
		for offset: Vector2i in Footprint.offsets_for(shape):
			var touches := offset == Vector2i.ZERO
			for neighbor: Vector2i in HexCoordinates.neighbors(offset):
				touches = touches or Footprint.offsets_for(shape).has(neighbor)
			assert_true(touches, "%s has a detached hex" % shape)


func test_the_triangle_is_three_mutually_adjacent_hexes() -> void:
	var offsets := Footprint.offsets_for(Footprint.Shape.TRIANGLE)
	for a: Vector2i in offsets:
		for b: Vector2i in offsets:
			assert_lte(HexCoordinates.distance(a, b), 1)


func test_the_bend_is_a_chain_whose_ends_are_two_apart_and_not_in_line() -> void:
	var offsets := Footprint.offsets_for(Footprint.Shape.BEND)
	assert_eq(HexCoordinates.distance(offsets[0], offsets[2]), 2)
	assert_ne(
		_canonical(offsets), _canonical(Footprint.offsets_for(Footprint.Shape.STRAIGHT)),
		"the bend must not be the straight in disguise"
	)


func test_each_shape_has_its_decided_number_of_distinct_footprints() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/56
	var expected := {
		Footprint.Shape.SINGLE: 1, Footprint.Shape.PAIR: 3, Footprint.Shape.STRAIGHT: 3,
		Footprint.Shape.BEND: 6, Footprint.Shape.TRIANGLE: 2,
	}
	for shape: Footprint.Shape in expected:
		var forms := {}
		for orientation in 6:
			forms[_canonical(
				Footprint.occupied(shape, orientation, Vector2i.ZERO, Vector2i.ZERO)
			)] = true
		assert_eq(forms.size(), expected[shape], "%s" % shape)


func test_the_grabbed_hex_lands_on_the_target() -> void:
	# The pivot is the grab hex, at every orientation.
	for orientation in 6:
		var occupied := Footprint.occupied(
			Footprint.Shape.STRAIGHT, orientation, Vector2i(2, -1), Vector2i(2, 0)
		)
		assert_true(occupied.has(Vector2i(2, -1)), "orientation %d" % orientation)


func test_a_rotated_footprint_keeps_its_hex_count_and_stays_connected() -> void:
	for orientation in 6:
		var occupied := Footprint.occupied(
			Footprint.Shape.BEND, orientation, Vector2i.ZERO, Vector2i(1, 0)
		)
		assert_eq(occupied.size(), 3)
		assert_eq(occupied.size(), {occupied[0]: 0, occupied[1]: 0, occupied[2]: 0}.size())


func test_orientation_wraps_and_six_steps_is_a_full_turn() -> void:
	assert_eq(
		Footprint.occupied(Footprint.Shape.BEND, 6, Vector2i.ZERO, Vector2i.ZERO),
		Footprint.occupied(Footprint.Shape.BEND, 0, Vector2i.ZERO, Vector2i.ZERO)
	)
	assert_eq(
		Footprint.occupied(Footprint.Shape.BEND, -1, Vector2i.ZERO, Vector2i.ZERO),
		Footprint.occupied(Footprint.Shape.BEND, 5, Vector2i.ZERO, Vector2i.ZERO)
	)
