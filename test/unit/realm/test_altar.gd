extends GutTest
## The Altar: a triangle-three with one gate, projecting nothing.

const ALTAR_PATH := "res://data/realm/altar/altar.tres"


func test_the_altar_is_a_triangle_three_with_one_gate() -> void:
	var altar: Altar = load(ALTAR_PATH)
	assert_eq(altar.shape, Footprint.Shape.TRIANGLE)
	assert_eq(altar.criteria.size(), 1)
	assert_true(altar.criteria[0] is LevelFootprintCriterion)


func test_the_altar_projects_nothing() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/77 — no domain, no radius,
	# no entry in #37's tally. Adding either is a design change, not a feature.
	var altar: Altar = load(ALTAR_PATH)
	assert_null(altar.zone_source)


func test_the_altar_reads_influence() -> void:
	var altar: Altar = load(ALTAR_PATH)
	assert_true(altar.reads_influence())
