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
