extends GutTest
## The realm scene: one targeted hex in, a previewed board out.

const REALM_SCENE := preload("res://realm/realm.tscn")


func _stool() -> Furniture:
	return load("res://data/realm/furniture/mushroom_stool.tres")


func _realm() -> Realm:
	var realm: Realm = add_child_autofree(REALM_SCENE.instantiate())
	await wait_frames(1)
	return realm


func _top(realm: Realm, hex: Vector2i) -> float:
	return realm.get_node("RealmBoard").hex_space(hex).top_height()


func test_the_scene_boots_with_a_board_a_cursor_and_a_carry() -> void:
	var realm := await _realm()
	assert_eq(realm.state.geometry.hexes().size(), 37)
	assert_not_null(realm.carry)
	assert_false(realm.carry.is_carrying())


func test_aiming_while_carrying_previews_the_ground_the_target_would_make() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/31
	var realm := await _realm()
	realm.state.place(FurniturePlacement.new(_stool(), 0, [Vector2i.ZERO] as Array[Vector2i]))
	realm.lift_from_inventory(_stool())
	realm.carry.aim(Vector2i(1, 0))
	assert_gt(
		_top(realm, Vector2i.ZERO), 0.0,
		"two Forest zones over the origin raise it while the piece is only targeted"
	)


func test_the_preview_resolves_on_a_refused_target_too() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/62 -- one read path.
	var realm := await _realm()
	realm.state.place(FurniturePlacement.new(_stool(), 0, [Vector2i.ZERO] as Array[Vector2i]))
	realm.lift_from_inventory(_stool())
	realm.carry.aim(Vector2i.ZERO)
	assert_false(realm.carry.verdict().allowed, "that hex is occupied")
	assert_gt(_top(realm, Vector2i.ZERO), 0.0)


func test_cancelling_puts_the_previewed_ground_back() -> void:
	var realm := await _realm()
	realm.state.place(FurniturePlacement.new(_stool(), 0, [Vector2i.ZERO] as Array[Vector2i]))
	realm.lift_from_inventory(_stool())
	realm.carry.aim(Vector2i(1, 0))
	realm.carry.cancel()
	assert_almost_eq(_top(realm, Vector2i.ZERO), 0.0, 0.0001)


func test_cancelling_a_piece_from_inventory_returns_it() -> void:
	var realm := await _realm()
	watch_signals(realm)
	realm.lift_from_inventory(_stool())
	realm.carry.cancel()
	assert_signal_emitted(realm, "piece_returned")


func test_lifting_a_placed_piece_drops_the_ground_it_was_holding_up() -> void:
	var realm := await _realm()
	for hex: Vector2i in [Vector2i.ZERO, Vector2i(1, 0)] as Array[Vector2i]:
		realm.state.place(FurniturePlacement.new(_stool(), 0, [hex] as Array[Vector2i]))
	realm._refresh_view()
	realm.board.zones = realm.state.zones()
	realm.board.rebuild(realm.state.geometry.hexes())
	assert_gt(_top(realm, Vector2i.ZERO), 0.0)
	realm.lift_under_cursor()
	assert_true(realm.carry.is_carrying())
	realm.carry.aim(Vector2i(-3, 0))
	assert_almost_eq(_top(realm, Vector2i.ZERO), 0.0, 0.0001)
	realm.carry.cancel()
	assert_gt(_top(realm, Vector2i.ZERO), 0.0, "cancel puts the ground back")


func test_placing_commits_the_piece_and_the_ground_it_raised() -> void:
	var realm := await _realm()
	realm.state.place(FurniturePlacement.new(_stool(), 0, [Vector2i.ZERO] as Array[Vector2i]))
	realm.lift_from_inventory(_stool())
	realm.carry.aim(Vector2i(1, 0))
	assert_true(realm.carry.place())
	assert_eq(realm.state.placements.size(), 2)
	assert_gt(_top(realm, Vector2i.ZERO), 0.0)


func test_rotating_while_idle_over_a_piece_lifts_it_turned() -> void:
	var realm := await _realm()
	realm.state.place(FurniturePlacement.new(_stool(), 0, [Vector2i.ZERO] as Array[Vector2i]))
	realm._rotate()
	assert_true(realm.carry.is_carrying())
	assert_eq(realm.carry.orientation, 1)


func test_rotating_while_idle_over_bare_ground_does_nothing() -> void:
	var realm := await _realm()
	realm._rotate()
	assert_false(realm.carry.is_carrying())


func test_a_swell_adds_the_ring_and_its_spaces() -> void:
	var realm := await _realm()
	realm.swell()
	await wait_frames(1)
	assert_eq(realm.state.geometry.hexes().size(), 61)
	assert_eq(realm.get_node("RealmBoard").get_child_count(), 61)


func test_a_swell_raises_ground_under_influence_that_was_spilling_into_nothing() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/59 -- the realm floods
	# into the space it just gained, with nothing newly placed.
	var realm := await _realm()
	for hex: Vector2i in [Vector2i(3, 0), Vector2i(3, -1)] as Array[Vector2i]:
		realm.state.place(FurniturePlacement.new(_stool(), 0, [hex] as Array[Vector2i]))
	realm.swell()
	await wait_frames(1)
	assert_gt(
		_top(realm, Vector2i(4, -1)), 0.0, "both rim pieces' zones already covered it"
	)


func test_the_realm_scene_is_still_not_the_main_scene() -> void:
	assert_eq(
		ProjectSettings.get_setting("application/run/main_scene"), "res://ui/title/title.tscn"
	)
