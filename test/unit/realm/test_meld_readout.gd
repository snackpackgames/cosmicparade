extends GutTest
## The meld probe: the whole derivation for one hex, as text.

const REALM_SCENE := preload("res://realm/realm.tscn")


func _effect(name: String) -> InfluenceEffect:
	var effect := InfluenceEffect.new()
	effect.effect_name = name
	return effect


func _entry(domains: Array[int], effect: InfluenceEffect) -> InfluenceEffectEntry:
	var entry := InfluenceEffectEntry.new()
	entry.domains = domains
	entry.effect = effect
	return entry


func _table(extra: Array[InfluenceEffectEntry] = []) -> InfluenceEffectTable:
	var table := InfluenceEffectTable.new()
	var entries: Array[InfluenceEffectEntry] = []
	entries.assign(extra)
	for domain: Domain.Kind in Domain.Kind.values():
		entries.append(
			_entry([domain], _effect((Domain.Kind.find_key(domain) as String).capitalize()))
		)
	table.entries = entries
	table.ceiling_effect = _effect("at ceiling")
	return table


func _zones(counts: Dictionary, hexes: Array[Vector2i]) -> Array[InfluenceZone]:
	var zones: Array[InfluenceZone] = []
	for domain: int in counts:
		for _i in counts[domain] as int:
			zones.append(InfluenceZone.new(domain, hexes))
	return zones


func _readout() -> MeldReadout:
	return add_child_autofree(MeldReadout.new())


func _lines(readout: MeldReadout) -> Array:
	return readout.text().split("\n")


func _realm() -> Realm:
	var realm: Realm = add_child_autofree(REALM_SCENE.instantiate())
	await wait_frames(1)
	return realm


func test_it_prints_the_whole_derivation_for_the_hex() -> void:
	var patch: Array[Vector2i] = [Vector2i(2, -1), Vector2i(3, -1), Vector2i(1, -1)]
	var table := _table(
		[_entry([Domain.Kind.FOREST, Domain.Kind.FLAME], _effect("fused placeholder"))]
	)
	var zones := _zones(
		{Domain.Kind.FOREST: 3, Domain.Kind.FLAME: 1, Domain.Kind.STONE: 2}, patch
	)
	var readout := _readout()
	readout.refresh(Vector2i(2, -1), zones, table)
	var lines := _lines(readout)
	assert_eq(lines[0], "Meld at (2,-1)")
	assert_eq(lines[1], "  covering   Forest x3, Stone x2, Flame x1")
	assert_eq(lines[2], "  entry 0    Forest+Flame   intensity 2, from Forest")
	assert_eq(lines[3], "  entry 4    Stone          intensity 1")
	assert_eq(lines[4], "  depth 2    from Forest, not at ceiling")
	assert_eq(lines[5], "  effects    fused placeholder, Stone")
	assert_eq(lines[6], "  region     3 hexes agree")
	assert_eq(lines.size(), 7)


func test_an_entry_line_carries_its_index_in_the_authored_file() -> void:
	var readout := _readout()
	readout.refresh(Vector2i.ZERO, _zones({Domain.Kind.GALE: 1}, [Vector2i.ZERO]), _table())
	assert_eq(_lines(readout)[2], "  entry 5    Gale           intensity 0")


func test_a_one_domain_entry_states_no_provenance_for_its_intensity() -> void:
	var readout := _readout()
	readout.refresh(Vector2i.ZERO, _zones({Domain.Kind.STONE: 3}, [Vector2i.ZERO]), _table())
	assert_eq(_lines(readout)[2], "  entry 3    Stone          intensity 2")


func test_at_the_ceiling_the_depth_line_says_so_and_the_effect_joins_the_set() -> void:
	var readout := _readout()
	var zones := _zones({Domain.Kind.STONE: Elevation.MAX_DEPTH + 1}, [Vector2i.ZERO])
	readout.refresh(Vector2i.ZERO, zones, _table())
	var lines := _lines(readout)
	assert_eq(lines[3], "  depth 4    from Stone, at ceiling")
	assert_eq(lines[4], "  effects    Stone, at ceiling")


func test_a_hex_nothing_covers_says_so_and_prints_no_other_line() -> void:
	var readout := _readout()
	readout.refresh(Vector2i(2, -1), [] as Array[InfluenceZone], _table())
	var lines := _lines(readout)
	assert_eq(lines[0], "Meld at (2,-1)")
	assert_eq(lines[1], MeldReadout.NOTHING_COVERS)
	assert_eq(lines.size(), 2)


func test_it_recovers_when_the_cursor_moves_back_onto_influence() -> void:
	var readout := _readout()
	var zones := _zones({Domain.Kind.GALE: 1}, [Vector2i.ZERO])
	readout.refresh(Vector2i.ZERO, zones, _table())
	readout.refresh(Vector2i(9, 9), zones, _table())
	assert_eq(_lines(readout)[1], MeldReadout.NOTHING_COVERS)
	readout.refresh(Vector2i.ZERO, zones, _table())
	assert_eq(_lines(readout).size(), 6)


func test_the_realm_feeds_the_probe_from_the_cursor() -> void:
	var realm := await _realm()
	realm.state.place(
		BoardPlacement.new(
			load("res://data/realm/furniture/mushroom_stool.tres"),
			0,
			[Vector2i(2, 0)] as Array[Vector2i]
		)
	)
	realm.cursor.aim_at(Vector2i(2, 0))
	assert_string_contains(realm.meld.text(), "Meld at (2,0)")
	assert_string_contains(realm.meld.text(), "Forest")


func test_the_probe_is_hidden_outside_a_debug_build() -> void:
	var realm := await _realm()
	assert_eq(realm.meld.visible, OS.is_debug_build())


func test_the_authored_table_resolves_a_hand_built_arrangement() -> void:
	var patch: Array[Vector2i] = [Vector2i(2, -1), Vector2i(3, -1), Vector2i(1, -1)]
	var table: InfluenceEffectTable = load(InfluenceEffectTable.BOARD_PATH)
	var zones := _zones(
		{Domain.Kind.FOREST: 3, Domain.Kind.FLAME: 1, Domain.Kind.STONE: 2}, patch
	)
	var readout := _readout()
	readout.refresh(Vector2i(2, -1), zones, table)
	var lines := _lines(readout)
	assert_eq(lines[1], "  covering   Forest x3, Stone x2, Flame x1")
	assert_string_contains(lines[2], "Forest+Flame")
	assert_string_contains(lines[2], "intensity 2, from Forest")
	assert_string_contains(lines[3], "Stone")
	assert_string_contains(lines[3], "intensity 1")
	assert_eq(lines[4], "  depth 2    from Forest, not at ceiling")
	assert_eq(lines[5], "  effects    fused placeholder, Stone")
	assert_eq(lines[6], "  region     3 hexes agree")
