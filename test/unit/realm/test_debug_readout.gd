extends GutTest
## The debug readout: the Altar's reading, the balance and the next Swell's price, as text. The
## last tests drive it through the realm scene, which is what wires it to all three.

const REALM_SCENE := preload("res://realm/realm.tscn")


func _fruit(domain: Domain.Kind) -> Fruit:
	var fruit := Fruit.new()
	fruit.fruit_name = "test fruit"
	fruit.domain = domain
	return fruit


func _shrine() -> Shrine:
	var shrine := Shrine.new()
	shrine.piece_name = "test shrine"
	shrine.zone_source = OfferingVessel.new()
	return shrine


func _altar() -> Altar:
	var altar := Altar.new()
	altar.piece_name = "test altar"
	altar.shape = Footprint.Shape.TRIANGLE
	altar.criteria = [LevelFootprintCriterion.new()] as Array[PlacementCriterion]
	return altar


func _state() -> RealmState:
	return RealmState.new(RealmGeometry.new())


func _place_shrine(state: RealmState, hex: Vector2i, domain: Domain.Kind) -> BoardPlacement:
	var placement := BoardPlacement.new(_shrine(), 0, [hex] as Array[Vector2i])
	placement.offer(_fruit(domain))
	state.place(placement)
	return placement


func _readout() -> DebugReadout:
	return add_child_autofree(DebugReadout.new())


func _realm() -> Realm:
	var realm: Realm = add_child_autofree(REALM_SCENE.instantiate())
	await wait_frames(1)
	realm.balance.grant(30)
	return realm


func _stool() -> Furniture:
	return load("res://data/realm/furniture/mushroom_stool.tres")


# A fed shrine standing on the board, with a Forest offering so the Altar reads "Forest".
func _fed_shrine(realm: Realm, hex: Vector2i) -> BoardPlacement:
	var placement := BoardPlacement.new(
		load("res://data/realm/shrine/plain_shrine.tres"), 0, [hex] as Array[Vector2i]
	)
	placement.offer(load("res://data/realm/fruit/moss_plum.tres"))
	realm.state.place(placement)
	return placement


func test_the_readout_names_each_domain_the_altar_reads() -> void:
	var state := _state()
	state.place_altar(_altar())
	_place_shrine(state, Vector2i(-1, 0), Domain.Kind.FOREST)
	var readout := _readout()
	readout.refresh(
		state.altar_reading(), AdherentBalance.new(), Swell.new(state, AdherentBalance.new())
	)
	assert_string_contains(readout.text(), "Forest 1")


func test_the_readout_omits_a_domain_the_altar_does_not_read() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/85 -- a domain at zero is absent
	# rather than listed as 0, the same way an empty vessel is absent from the tally.
	var state := _state()
	state.place_altar(_altar())
	_place_shrine(state, Vector2i(-1, 0), Domain.Kind.FLAME)
	var readout := _readout()
	readout.refresh(
		state.altar_reading(), AdherentBalance.new(), Swell.new(state, AdherentBalance.new())
	)
	assert_string_contains(readout.text(), "Flame 1")
	assert_false(readout.text().contains("Forest"), "nothing Forest reaches the Altar")


func test_the_readout_states_the_readings_range() -> void:
	var state := _state()
	state.place_altar(_altar())
	var readout := _readout()
	readout.refresh(
		state.altar_reading(), AdherentBalance.new(), Swell.new(state, AdherentBalance.new())
	)
	assert_string_contains(readout.text(), DebugReadout.READING_RANGE)


func test_the_readout_shows_the_balance_and_the_next_swells_price_and_grant() -> void:
	var state := _state()
	state.place_altar(_altar())
	var balance := AdherentBalance.new()
	balance.grant(25)
	var readout := _readout()
	readout.refresh(state.altar_reading(), balance, Swell.new(state, balance))
	assert_string_contains(readout.text(), "25")
	assert_string_contains(readout.text(), "10", "the first ring Swell's price")
	assert_string_contains(readout.text(), "a ring")
	assert_string_contains(readout.text(), "shrine capacity")


func test_the_readout_says_when_there_is_no_further_swell() -> void:
	var state := _state()
	state.place_altar(_altar())
	var swell := Swell.new(state, AdherentBalance.new())
	swell.tiers_taken = 6
	var readout := _readout()
	readout.refresh(state.altar_reading(), AdherentBalance.new(), swell)
	assert_string_contains(readout.text(), "no further Swell")


func test_the_debug_grant_is_the_first_swells_price() -> void:
	assert_eq(Swell.DEBUG_GRANT, 10)
	assert_eq(Swell.DEBUG_GRANT, (load(Swell.TIER_PATHS[0]) as SwellTier).cost)

func test_the_realm_feeds_the_readout_all_three_numbers() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/85 -- one rule for all three,
	# and the realm feeds them from the board and wallet it already owns.
	var realm := await _realm()
	_fed_shrine(realm, Vector2i(-1, 0))
	realm.take_ring()
	assert_string_contains(realm.readout.text(), "Forest 1")
	assert_string_contains(realm.readout.text(), "Adherents 20", "30 granted, 10 spent")
	assert_string_contains(realm.readout.text(), "Second Ring", "the next price, not the last")


func test_the_readout_tracks_a_fed_shrine_while_it_is_carried() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/85 -- it updates live while a
	# piece is carried, not only when one lands.
	var realm := await _realm()
	_fed_shrine(realm, Vector2i(-1, 0))
	realm.cursor.aim_at(Vector2i(-1, 0))
	realm.lift_under_cursor()
	assert_string_contains(realm.readout.text(), "Forest 1", "still reaching, from the hand")

	realm.carry.aim(Vector2i(-3, 0))

	assert_false(realm.readout.text().contains("Forest"), "carried out of the Altar's reach")


func test_a_carried_piece_of_furniture_never_enters_the_altars_reading() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/79 -- the reading is shrine
	# zones only, and a candidate zone is no exception.
	var realm := await _realm()
	realm.lift_from_inventory(_stool())
	realm.carry.aim(Vector2i(2, 0))
	assert_true(realm.carry.verdict().allowed, "a legal target, one hex off the Altar")
	assert_false(realm.readout.text().contains("Forest"))
