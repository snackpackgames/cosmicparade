extends GutTest
## The authored influence effect table: the shape of the data and the guards on what is authored.

const AUTHORED := InfluenceEffectTable.BOARD_PATH


func _authored() -> InfluenceEffectTable:
	return load(AUTHORED)


func test_an_effect_extends_the_game_data_base() -> void:
	assert_is(InfluenceEffect.new(), GameData)


func test_an_effect_carries_an_authored_name() -> void:
	var effect := InfluenceEffect.new()
	effect.effect_name = "Forest"
	assert_eq(effect.effect_name, "Forest")


func test_a_table_holds_ordered_entries_and_one_ceiling_effect() -> void:
	var table := InfluenceEffectTable.new()
	var entry := InfluenceEffectEntry.new()
	entry.domains = [Domain.Kind.STONE]
	table.entries = [entry] as Array[InfluenceEffectEntry]
	table.ceiling_effect = InfluenceEffect.new()
	assert_eq(table.entries.size(), 1)
	assert_not_null(table.ceiling_effect)
	assert_is(table, GameData)


# https://github.com/snackpackgames/cosmicparade/issues/113 — the completeness guard that replaces
# what a fixed six-slot array gave for free. A domain with no one-domain entry renders nothing.
func test_every_domain_has_a_one_domain_entry() -> void:
	var claimed: Dictionary = {}
	for entry: InfluenceEffectEntry in _authored().entries:
		if entry.domains.size() == 1:
			claimed[entry.domains[0]] = true
	for domain: Domain.Kind in Domain.Kind.values():
		assert_true(claimed.has(domain), "no one-domain entry for %s" % Domain.Kind.find_key(domain))


# https://github.com/snackpackgames/cosmicparade/issues/114 — an unnamed effect prints empty in the
# probe with nothing to catch it.
func test_every_authored_effect_is_named() -> void:
	var table := _authored()
	for entry: InfluenceEffectEntry in table.entries:
		assert_not_null(entry.effect)
		assert_ne(entry.effect.effect_name, "")
	assert_not_null(table.ceiling_effect)
	assert_ne(table.ceiling_effect.effect_name, "")


# https://github.com/snackpackgames/cosmicparade/issues/107 — no empty entries, and no duplicate
# key: a second entry claiming the same set could never win a tie, so it is dead data.
func test_no_entry_is_empty_and_no_domain_set_repeats() -> void:
	var seen: Dictionary = {}
	for entry: InfluenceEffectEntry in _authored().entries:
		assert_false(entry.domains.is_empty())
		var sorted := entry.domains.duplicate()
		sorted.sort()
		assert_eq(sorted.size(), entry.domains.size())
		var key := ",".join(sorted.map(func(domain: int) -> String: return str(domain)))
		assert_false(seen.has(key), "two entries claim %s" % key)
		seen[key] = true


# The placeholder set the map's scope allows: six one-domain entries plus one combination.
func test_the_authored_table_ships_one_placeholder_combination() -> void:
	var combinations := 0
	for entry: InfluenceEffectEntry in _authored().entries:
		if entry.domains.size() > 1:
			combinations += 1
	assert_eq(combinations, 1)
