extends GutTest
## The four authored wing figures.
## https://github.com/snackpackgames/cosmicparade/issues/61

const SHAPES := {
	"disc": [7, 1],
	"trapezoid": [7, 6],
	"triangle": [6, 2],
	"rhombus": [6, 3],
}


func _shape(name: String) -> WingShape:
	return load("res://data/realm/wing_shape/%s.tres" % name)


func _canonical(offsets: Array[Vector2i]) -> Array:
	# Translation-invariant form: the smallest sorted offset list over every
	# choice of which hex sits at the origin.
	var best: Array = []
	for anchor: Vector2i in offsets:
		var form: Array[Vector2i] = []
		for offset: Vector2i in offsets:
			form.append(offset - anchor)
		form.sort()
		if best.is_empty() or form < best:
			best = form
	return best


func test_the_roster_is_exactly_four_entries() -> void:
	assert_eq(DirAccess.get_files_at("res://data/realm/wing_shape").size(), 4)


func test_every_entry_has_its_decided_size_and_orientation_count() -> void:
	for name: String in SHAPES:
		var shape := _shape(name)
		assert_eq(shape.offsets.size(), SHAPES[name][0], "%s size" % name)
		assert_eq(shape.distinct_orientations, SHAPES[name][1], "%s orientations" % name)


func test_the_authored_orientation_count_matches_rotating_the_offsets() -> void:
	for name: String in SHAPES:
		var shape := _shape(name)
		var forms := {}
		for steps in 6:
			forms[_canonical(shape.rotated_offsets(steps))] = true
		assert_eq(forms.size(), shape.distinct_orientations, "%s" % name)


func test_every_entry_is_edge_connected() -> void:
	for name: String in SHAPES:
		var shape := _shape(name)
		var remaining := {}
		for offset: Vector2i in shape.offsets:
			remaining[offset] = true
		var frontier: Array[Vector2i] = [shape.offsets[0]]
		var reached := 0
		remaining.erase(shape.offsets[0])
		while not frontier.is_empty():
			reached += 1
			for neighbor: Vector2i in HexCoordinates.neighbors(frontier.pop_back()):
				if remaining.erase(neighbor):
					frontier.append(neighbor)
		assert_eq(reached, shape.offsets.size(), "%s is one patch" % name)


func test_rotating_by_zero_returns_the_authored_offsets() -> void:
	assert_eq(_shape("trapezoid").rotated_offsets(0), _shape("trapezoid").offsets)


func test_rotation_preserves_the_hex_count() -> void:
	assert_eq(_shape("trapezoid").rotated_offsets(3).size(), 7)
