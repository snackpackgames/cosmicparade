extends GutTest
## Meld resolution: which authored influence effects a hex shows, and at what intensity.


func _effect(name: String) -> InfluenceEffect:
	var effect := InfluenceEffect.new()
	effect.effect_name = name
	return effect


func _entry(domains: Array[int], effect: InfluenceEffect) -> InfluenceEffectEntry:
	var entry := InfluenceEffectEntry.new()
	entry.domains = domains
	entry.effect = effect
	return entry


# A table of one-domain entries for every domain, named for the domain, plus whatever extra
# entries a test wants in front of them — in front, because order is the tie-break.
func _table(extra: Array[InfluenceEffectEntry] = []) -> InfluenceEffectTable:
	var table := InfluenceEffectTable.new()
	var entries: Array[InfluenceEffectEntry] = []
	entries.assign(extra)
	for domain: Domain.Kind in Domain.Kind.values():
		entries.append(_entry([domain], _effect(Domain.Kind.find_key(domain) as String)))
	table.entries = entries
	table.ceiling_effect = _effect("ceiling")
	return table


func _zones(counts: Dictionary, hex: Vector2i = Vector2i.ZERO) -> Array[InfluenceZone]:
	var zones: Array[InfluenceZone] = []
	for domain: int in counts:
		for _i in counts[domain] as int:
			zones.append(InfluenceZone.new(domain, [hex] as Array[Vector2i]))
	return zones


func _names(effects: Array[InfluenceEffect]) -> Array[String]:
	var names: Array[String] = []
	for effect in effects:
		names.append(effect.effect_name)
	return names


# https://github.com/snackpackgames/cosmicparade/issues/107 — a hex nothing covers has no effects
# at all. The table holds nothing for it, by construction.
func test_a_hex_nothing_covers_resolves_to_nothing() -> void:
	var resolution := Meld.resolve(Vector2i.ZERO, [] as Array[InfluenceZone], _table())
	assert_true(resolution.is_empty())
	assert_eq(resolution.matches.size(), 0)
	assert_eq(resolution.effects().size(), 0)
	assert_eq(resolution.depth, 0)
	assert_false(resolution.at_ceiling)


func test_one_domain_fires_its_own_entry() -> void:
	var resolution := Meld.resolve(
		Vector2i.ZERO, _zones({Domain.Kind.STONE: 1}), _table()
	)
	assert_false(resolution.is_empty())
	assert_eq(_names(resolution.effects()), ["STONE"] as Array[String])
	assert_eq(resolution.matches[0].domains, [Domain.Kind.STONE] as Array[int])


func test_a_pair_entry_wins_and_consumes_both_its_domains() -> void:
	var fused := _effect("fused")
	var table := _table([_entry([Domain.Kind.FOREST, Domain.Kind.FLAME], fused)])
	var resolution := Meld.resolve(
		Vector2i.ZERO, _zones({Domain.Kind.FOREST: 1, Domain.Kind.FLAME: 1}), table
	)
	assert_eq(_names(resolution.effects()), ["fused"] as Array[String])
	assert_eq(resolution.matches.size(), 1)
	assert_eq(resolution.matches[0].entry_index, 0)


# The worked example from #107: Forest, Flame and Wetland, with the pair authored and no triple.
func test_a_domain_no_entry_claimed_fires_its_own_one_domain_entry() -> void:
	var table := _table([_entry([Domain.Kind.FOREST, Domain.Kind.FLAME], _effect("fused"))])
	var resolution := Meld.resolve(
		Vector2i.ZERO,
		_zones({Domain.Kind.FOREST: 1, Domain.Kind.FLAME: 1, Domain.Kind.WETLAND: 1}),
		table
	)
	assert_eq(_names(resolution.effects()), ["fused", "WETLAND"] as Array[String])


func test_the_largest_subset_wins_over_a_pair_it_contains() -> void:
	var table := _table([
		_entry([Domain.Kind.FOREST, Domain.Kind.FLAME], _effect("pair")),
		_entry([Domain.Kind.FOREST, Domain.Kind.FLAME, Domain.Kind.STONE], _effect("triple")),
	])
	var resolution := Meld.resolve(
		Vector2i.ZERO,
		_zones({Domain.Kind.FOREST: 1, Domain.Kind.FLAME: 1, Domain.Kind.STONE: 1}),
		table
	)
	assert_eq(_names(resolution.effects()), ["triple"] as Array[String])


func test_a_tie_between_equal_sized_entries_goes_to_the_earlier_in_the_file() -> void:
	var table := _table([
		_entry([Domain.Kind.FOREST, Domain.Kind.FLAME], _effect("first")),
		_entry([Domain.Kind.FOREST, Domain.Kind.STONE], _effect("second")),
	])
	var resolution := Meld.resolve(
		Vector2i.ZERO,
		_zones({Domain.Kind.FOREST: 1, Domain.Kind.FLAME: 1, Domain.Kind.STONE: 1}),
		table
	)
	assert_eq(_names(resolution.effects()), ["first", "STONE"] as Array[String])


# Review Focus 1: a domain covers the hex and the table claims it nowhere. It contributes nothing
# — no match, no null member — and the hex renders less than the player's influence implies, which
# is what Task 1.4's completeness guard exists to prevent in the authored file.
func test_a_domain_no_entry_claims_at_all_contributes_nothing() -> void:
	var table := InfluenceEffectTable.new()
	table.entries = [_entry([Domain.Kind.STONE], _effect("Stone"))] as Array[InfluenceEffectEntry]
	var resolution := Meld.resolve(
		Vector2i.ZERO, _zones({Domain.Kind.STONE: 1, Domain.Kind.GALE: 2}), table
	)
	assert_eq(_names(resolution.effects()), ["Stone"] as Array[String])
	assert_eq(resolution.matches.size(), 1)
	assert_eq(resolution.depth, 1, "Gale still raises the hex it shows nothing on")


# Review Focus 2: the empty set is a subset of everything, so an authored zero-domain entry must
# never match and must never hang the loop.
func test_an_entry_claiming_no_domains_is_skipped() -> void:
	var table := _table([_entry([], _effect("empty"))])
	var resolution := Meld.resolve(Vector2i.ZERO, _zones({Domain.Kind.GALE: 1}), table)
	assert_eq(_names(resolution.effects()), ["GALE"] as Array[String])


func test_a_fused_effect_is_amplified_by_its_own_domains_not_by_the_hex() -> void:
	var table := _table([_entry([Domain.Kind.FOREST, Domain.Kind.FLAME], _effect("fused"))])
	var resolution := Meld.resolve(
		Vector2i.ZERO,
		_zones({Domain.Kind.STONE: 4, Domain.Kind.FOREST: 2, Domain.Kind.FLAME: 1}),
		table
	)
	assert_eq(resolution.depth, 3, "the hex's depth comes from Stone")
	assert_eq(resolution.depth_domain, Domain.Kind.STONE)
	var fused := resolution.matches[0]
	assert_eq(fused.effect.effect_name, "fused")
	assert_eq(fused.intensity, 1, "Forest's depth, the max of Forest's 1 and Flame's 0")
	assert_eq(fused.intensity_domain, Domain.Kind.FOREST)
	var stone := resolution.matches[1]
	assert_eq(stone.intensity, 3)
	assert_eq(stone.intensity_domain, Domain.Kind.STONE)


func test_a_one_domain_effect_is_amplified_by_that_domain() -> void:
	var resolution := Meld.resolve(
		Vector2i.ZERO, _zones({Domain.Kind.WETLAND: 3}), _table()
	)
	assert_eq(resolution.matches[0].intensity, 2)
	assert_eq(resolution.matches[0].intensity_domain, Domain.Kind.WETLAND)


func test_a_lone_zone_amplifies_nothing() -> void:
	var resolution := Meld.resolve(Vector2i.ZERO, _zones({Domain.Kind.GALE: 1}), _table())
	assert_eq(resolution.matches[0].intensity, 0)


func test_the_ceiling_effect_joins_the_set_at_the_maximum_depth() -> void:
	var table := _table()
	var resolution := Meld.resolve(
		Vector2i.ZERO, _zones({Domain.Kind.STONE: Elevation.MAX_DEPTH + 1}), table
	)
	assert_true(resolution.at_ceiling)
	assert_eq(_names(resolution.effects()), ["STONE", "ceiling"] as Array[String])


func test_below_the_maximum_depth_the_ceiling_effect_is_absent() -> void:
	var resolution := Meld.resolve(
		Vector2i.ZERO, _zones({Domain.Kind.STONE: Elevation.MAX_DEPTH}), _table()
	)
	assert_false(resolution.at_ceiling)
	assert_eq(_names(resolution.effects()), ["STONE"] as Array[String])


# Review Focus 3: the ceiling is a fact about depth, not about what is authored. A table with no
# ceiling effect still reports the hex as at its ceiling, and must not put a null in the set.
func test_an_unauthored_ceiling_effect_leaves_the_set_clean() -> void:
	var table := _table()
	table.ceiling_effect = null
	var resolution := Meld.resolve(
		Vector2i.ZERO, _zones({Domain.Kind.STONE: Elevation.MAX_DEPTH + 1}), table
	)
	assert_true(resolution.at_ceiling)
	assert_eq(_names(resolution.effects()), ["STONE"] as Array[String])


# https://github.com/snackpackgames/cosmicparade/issues/109 — the pin that decision asked for.
# "Consumed" is a statement about effects and only about effects: a consumed domain still raises
# its hex, so the authored table can never change what can legally be placed.
func test_depth_is_identical_with_and_without_a_matching_entry() -> void:
	var zones := _zones({Domain.Kind.FOREST: 3, Domain.Kind.FLAME: 2})
	var bare := _table()
	var fused := _table([_entry([Domain.Kind.FOREST, Domain.Kind.FLAME], _effect("fused"))])
	assert_eq(Meld.resolve(Vector2i.ZERO, zones, bare).depth, 2)
	assert_eq(Meld.resolve(Vector2i.ZERO, zones, fused).depth, 2)
	assert_eq(Elevation.depth_at(Vector2i.ZERO, zones), 2)
	assert_eq(Elevation.height_at(Vector2i.ZERO, zones), Elevation.height_for_depth(2))


func test_two_hexes_with_the_same_effects_agree_whatever_their_intensities() -> void:
	var table := _table()
	var shallow := Meld.resolve(Vector2i.ZERO, _zones({Domain.Kind.STONE: 1}), table)
	var deep := Meld.resolve(Vector2i.ZERO, _zones({Domain.Kind.STONE: 3}), table)
	assert_true(shallow.agrees_with(deep))
	assert_true(deep.agrees_with(shallow))


func test_hexes_differing_by_the_ceiling_effect_alone_disagree() -> void:
	var table := _table()
	var below := Meld.resolve(
		Vector2i.ZERO, _zones({Domain.Kind.STONE: Elevation.MAX_DEPTH}), table
	)
	var at := Meld.resolve(
		Vector2i.ZERO, _zones({Domain.Kind.STONE: Elevation.MAX_DEPTH + 1}), table
	)
	assert_false(below.agrees_with(at))


func test_different_domains_disagree_and_two_bare_hexes_agree() -> void:
	var table := _table()
	var stone := Meld.resolve(Vector2i.ZERO, _zones({Domain.Kind.STONE: 1}), table)
	var gale := Meld.resolve(Vector2i.ZERO, _zones({Domain.Kind.GALE: 1}), table)
	var nothing := Meld.resolve(Vector2i.ZERO, [] as Array[InfluenceZone], table)
	assert_false(stone.agrees_with(gale))
	assert_false(stone.agrees_with(nothing))
	assert_true(nothing.agrees_with(Meld.resolve(Vector2i(9, 9), [] as Array[InfluenceZone], table)))


func _patch(domain: Domain.Kind, hexes: Array[Vector2i]) -> InfluenceZone:
	return InfluenceZone.new(domain, hexes)


func test_a_region_is_every_contiguous_hex_whose_effects_agree() -> void:
	var zones: Array[InfluenceZone] = [
		_patch(Domain.Kind.STONE, [Vector2i.ZERO, Vector2i(1, 0), Vector2i(2, 0)])
	]
	var region := Meld.region_at(Vector2i.ZERO, zones, _table())
	assert_eq(region.size(), 3)
	assert_eq(_names(region.effects), ["STONE"] as Array[String])


func test_hexes_that_do_not_touch_are_two_regions() -> void:
	var zones: Array[InfluenceZone] = [
		_patch(Domain.Kind.STONE, [Vector2i.ZERO, Vector2i(4, 0)])
	]
	assert_eq(Meld.region_at(Vector2i.ZERO, zones, _table()).size(), 1)
	assert_eq(Meld.region_at(Vector2i(4, 0), zones, _table()).size(), 1)


func test_a_neighbour_showing_different_effects_ends_the_region() -> void:
	var zones: Array[InfluenceZone] = [
		_patch(Domain.Kind.STONE, [Vector2i.ZERO, Vector2i(1, 0)]),
		_patch(Domain.Kind.GALE, [Vector2i(1, 0)]),
	]
	var table := _table()
	assert_eq(Meld.region_at(Vector2i.ZERO, zones, table).size(), 1)
	assert_eq(_names(Meld.region_at(Vector2i(1, 0), zones, table).effects),
		["STONE", "GALE"] as Array[String])


func test_every_region_on_the_board_is_grouped_once() -> void:
	var zones: Array[InfluenceZone] = [
		_patch(Domain.Kind.STONE, [Vector2i.ZERO, Vector2i(1, 0)]),
		_patch(Domain.Kind.GALE, [Vector2i(6, 0)]),
	]
	var regions := Meld.regions(zones, _table())
	assert_eq(regions.size(), 2)
	var total := 0
	for region in regions:
		total += region.size()
	assert_eq(total, 3)


func test_regions_agrees_with_region_at_for_the_same_hex() -> void:
	var zones: Array[InfluenceZone] = [
		_patch(Domain.Kind.STONE, HexCoordinates.disc(Vector2i.ZERO, 2))
	]
	var table := _table()
	var one := Meld.region_at(Vector2i(1, 0), zones, table)
	var found := 0
	for region in Meld.regions(zones, table):
		if region.contains(Vector2i(1, 0)):
			found += 1
			assert_eq(region.size(), one.size())
	assert_eq(found, 1)


func test_no_region_covers_a_hex_nothing_covers() -> void:
	assert_true(Meld.regions([] as Array[InfluenceZone], _table()).is_empty())


# https://github.com/snackpackgames/cosmicparade/issues/109 — a melded area straddling the depth-4
# contour is two regions, because the ceiling effect is in the set a region compares. Stacking
# MAX_DEPTH + 1 zones on one hex of a patch puts that hex alone at its ceiling.
func test_a_patch_straddling_the_ceiling_contour_is_three_regions() -> void:
	var patch: Array[Vector2i] = [Vector2i.ZERO, Vector2i(1, 0), Vector2i(2, 0)]
	var zones: Array[InfluenceZone] = [_patch(Domain.Kind.STONE, patch)]
	for _i in Elevation.MAX_DEPTH:
		zones.append(_patch(Domain.Kind.STONE, [Vector2i(1, 0)]))
	var table := _table()
	assert_eq(Elevation.depth_at(Vector2i(1, 0), zones), Elevation.MAX_DEPTH)
	assert_eq(Meld.regions(zones, table).size(), 3, "the maxed hex severs the patch")
	assert_eq(Meld.region_at(Vector2i(1, 0), zones, table).size(), 1)
	assert_eq(Meld.region_at(Vector2i.ZERO, zones, table).size(), 1)


func test_region_at_a_hex_nothing_covers_is_null() -> void:
	assert_null(Meld.region_at(Vector2i(3, 3), [] as Array[InfluenceZone], _table()))


# InfluenceZone keeps the coordinates that land in the void and clips at consumption, so
# resolution and regions answer for them like any other hex.
func test_resolution_and_regions_answer_for_coordinates_in_the_void() -> void:
	var void_hexes: Array[Vector2i] = [Vector2i(40, 0), Vector2i(41, 0)]
	var zones: Array[InfluenceZone] = [_patch(Domain.Kind.FLAME, void_hexes)]
	var table := _table()
	assert_eq(_names(Meld.resolve(Vector2i(40, 0), zones, table).effects()),
		["FLAME"] as Array[String])
	assert_eq(Meld.regions(zones, table).size(), 1)
	assert_eq(Meld.region_at(Vector2i(40, 0), zones, table).size(), 2)
