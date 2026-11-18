extends GutTest

const EXPECTED := [
	["First Ring", SwellTier.Effect.RING, 1, 10],
	["Second Ring", SwellTier.Effect.RING, 1, 20],
	["First Wing", SwellTier.Effect.WING, 0, 40],
	["Second Wing", SwellTier.Effect.WING, 0, 70],
	["Third Wing", SwellTier.Effect.WING, 0, 110],
	["Fourth Wing", SwellTier.Effect.WING, 0, 160],
]


func test_the_table_is_six_rows_in_the_decided_order() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/80 (grants) and
	# https://github.com/snackpackgames/cosmicparade/issues/81 (costs). A seventh row is
	# a design change: past the fourth wing Swell grants nothing realm-side.
	assert_eq(Swell.TIER_PATHS.size(), 6)
	for index: int in EXPECTED.size():
		var tier: SwellTier = load(Swell.TIER_PATHS[index])
		assert_eq(tier.tier_name, EXPECTED[index][0])
		assert_eq(tier.board_effect, EXPECTED[index][1])
		assert_eq(tier.shrine_capacity_delta, EXPECTED[index][2])
		assert_eq(tier.cost, EXPECTED[index][3])


func test_the_ladder_totals_four_hundred_and_ten() -> void:
	var total := 0
	for path: String in Swell.TIER_PATHS:
		total += (load(path) as SwellTier).cost
	assert_eq(total, 410)


func test_capacity_rises_by_two_across_the_whole_ladder() -> void:
	var delta := 0
	for path: String in Swell.TIER_PATHS:
		delta += (load(path) as SwellTier).shrine_capacity_delta
	assert_eq(delta, 2)
	assert_eq(RealmState.STARTING_SHRINE_CAPACITY + delta, 4)
