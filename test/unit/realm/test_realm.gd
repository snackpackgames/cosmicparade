extends GutTest
## The realm scene: one targeted hex in, a previewed board out.

const REALM_SCENE := preload("res://realm/realm.tscn")


func _stool() -> Furniture:
	return load("res://data/realm/furniture/mushroom_stool.tres")


func _bench() -> Furniture:
	return load("res://data/realm/furniture/fern_bench.tres")


func _disc() -> WingShape:
	return load("res://data/realm/wing_shape/disc.tres")


func _realm() -> Realm:
	var realm: Realm = add_child_autofree(REALM_SCENE.instantiate())
	await wait_frames(1)
	return realm


# The scene stands its Altar on the origin; tests that need the origin bare take it off.
func _bare_realm() -> Realm:
	var realm := await _realm()
	realm.state.remove(realm.state.altar_placement)
	return realm


## A radius-5 core with a disc wing anchored at (7, -1): 98 spaces, the wing's index 0.
func _wing_on_the_board() -> Realm:
	var realm := await _realm()
	realm.swell()
	realm.swell()
	realm.attach_wing(_disc())
	realm.carry.aim(Vector2i(7, -1))
	realm.carry.place()
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
	realm.state.place(BoardPlacement.new(_stool(), 0, [Vector2i.ZERO] as Array[Vector2i]))
	realm.lift_from_inventory(_stool())
	realm.carry.aim(Vector2i(1, 0))
	assert_gt(
		_top(realm, Vector2i.ZERO), 0.0,
		"two Forest zones over the origin raise it while the piece is only targeted"
	)


func test_the_preview_resolves_on_a_refused_target_too() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/62 -- one read path.
	var realm := await _realm()
	realm.state.place(BoardPlacement.new(_stool(), 0, [Vector2i.ZERO] as Array[Vector2i]))
	realm.lift_from_inventory(_stool())
	realm.carry.aim(Vector2i.ZERO)
	assert_false(realm.carry.verdict().allowed, "that hex is occupied")
	assert_gt(_top(realm, Vector2i.ZERO), 0.0)


func test_cancelling_puts_the_previewed_ground_back() -> void:
	var realm := await _realm()
	realm.state.place(BoardPlacement.new(_stool(), 0, [Vector2i.ZERO] as Array[Vector2i]))
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
		realm.state.place(BoardPlacement.new(_stool(), 0, [hex] as Array[Vector2i]))
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
	var realm := await _bare_realm()
	realm.state.place(BoardPlacement.new(_stool(), 0, [Vector2i.ZERO] as Array[Vector2i]))
	realm.lift_from_inventory(_stool())
	realm.carry.aim(Vector2i(1, 0))
	assert_true(realm.carry.place())
	assert_eq(realm.state.placements.size(), 2)
	assert_gt(_top(realm, Vector2i.ZERO), 0.0)


func test_rotating_while_idle_over_a_piece_lifts_it_turned() -> void:
	var realm := await _realm()
	realm.state.place(BoardPlacement.new(_stool(), 0, [Vector2i.ZERO] as Array[Vector2i]))
	realm._rotate()
	assert_true(realm.carry.is_carrying())
	assert_eq(realm.carry.orientation, 1)


func test_rotating_while_idle_over_bare_ground_does_nothing() -> void:
	var realm := await _bare_realm()
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
		realm.state.place(BoardPlacement.new(_stool(), 0, [hex] as Array[Vector2i]))
	realm.swell()
	await wait_frames(1)
	assert_gt(
		_top(realm, Vector2i(4, -1)), 0.0, "both rim pieces' zones already covered it"
	)


func test_the_realm_scene_is_still_not_the_main_scene() -> void:
	assert_eq(
		ProjectSettings.get_setting("application/run/main_scene"), "res://ui/title/title.tscn"
	)


func test_the_board_says_nothing_until_a_target_fails() -> void:
	var realm := await _bare_realm()
	realm.lift_from_inventory(_stool())
	assert_eq(realm.refusal.marked_hexes(), [] as Array[Vector2i])
	assert_eq(realm.requirements.lines(), [])


func test_a_refusal_marks_the_hexes_and_the_requirements_at_once() -> void:
	var realm := await _bare_realm()
	realm.lift_from_inventory(_bench())
	realm.carry.aim(Vector2i.ZERO)
	assert_eq(realm.refusal.marked_hexes().size(), 3)
	assert_eq(realm.requirements.failing_lines(), ["Forest >= 2"])


func test_both_channels_clear_when_the_carry_ends() -> void:
	var realm := await _realm()
	realm.lift_from_inventory(_bench())
	realm.carry.aim(Vector2i.ZERO)
	realm.carry.cancel()
	assert_eq(realm.refusal.marked_hexes(), [] as Array[Vector2i])
	assert_eq(realm.requirements.lines(), [])


func test_carrying_over_the_rim_draws_the_spill_without_refusing_the_placement() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/59
	var realm := await _realm()
	realm.lift_from_inventory(_stool())
	realm.carry.aim(Vector2i(3, -1))
	assert_true(realm.carry.verdict().allowed)
	assert_eq(realm.spill.spilled_hexes().size(), 2)
	assert_eq(realm.refusal.marked_hexes(), [] as Array[Vector2i])


func test_lifting_an_unplaceable_piece_announces_the_requirement_nothing_satisfies() -> void:
	var realm := await _realm()
	watch_signals(realm)
	realm.lift_from_inventory(_bench())
	assert_signal_emitted(realm, "nothing_satisfies")
	assert_true(realm.carry.is_carrying(), "the player still gets to carry it and look")


func test_lifting_a_placeable_piece_announces_nothing() -> void:
	var realm := await _realm()
	watch_signals(realm)
	realm.lift_from_inventory(_stool())
	assert_signal_not_emitted(realm, "nothing_satisfies")


func test_attaching_a_wing_goes_through_the_same_carry() -> void:
	var realm := await _realm()
	realm.swell()
	realm.swell()
	realm.attach_wing(_disc())
	assert_true(realm.carry.is_carrying())
	realm.carry.aim(Vector2i(7, -1))
	assert_true(realm.carry.place())
	await wait_frames(1)
	assert_eq(realm.state.geometry.hexes().size(), 98)
	assert_eq(realm.get_node("RealmBoard").get_child_count(), 98)


func test_cancelling_a_wing_attachment_leaves_the_board_as_it_was() -> void:
	var realm := await _realm()
	realm.swell()
	realm.swell()
	realm.attach_wing(_disc())
	realm.carry.aim(Vector2i(7, -1))
	realm.carry.cancel()
	await wait_frames(1)
	assert_eq(realm.state.geometry.hexes().size(), 91)


func test_lifting_a_wing_takes_its_spaces_off_the_board_for_the_carry() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/54 -- a carried thing
	# occupies nothing, and a wing is ground, so the ground goes with it.
	var realm := await _wing_on_the_board()
	realm.cursor.aim_at(Vector2i(7, -1))
	realm.lift_wing_under_cursor()
	await wait_frames(1)
	assert_true(realm.carry.is_carrying())
	assert_eq(realm.get_node("RealmBoard").get_child_count(), 91)


func test_a_piece_straddling_a_relocated_wing_is_announced_as_returned() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/53
	var realm := await _wing_on_the_board()
	realm.state.place(BoardPlacement.new(
		_bench(), 0,
		Footprint.occupied(Footprint.Shape.STRAIGHT, 0, Vector2i(6, -1), Vector2i(1, 0))
	))
	watch_signals(realm)
	realm.cursor.aim_at(Vector2i(7, -1))
	realm.lift_wing_under_cursor()
	realm.carry.aim(Vector2i(1, 6))
	assert_true(realm.carry.place())
	await wait_frames(1)
	assert_signal_emitted(realm, "piece_returned")
	assert_eq(realm.state.geometry.hexes().size(), 98, "no hexes were lost")


func test_a_wing_whose_lift_would_orphan_the_board_is_not_lifted() -> void:
	var realm := await _wing_on_the_board()
	realm.state.geometry.attach(_disc(), 0, Vector2i(10, -2))
	realm.cursor.aim_at(Vector2i(7, -1))
	realm.lift_wing_under_cursor()
	assert_false(realm.carry.is_carrying())


func test_lifting_from_an_empty_stock_does_nothing() -> void:
	# Review Focus 3. Capacity is the only thing limiting shrines
	# (https://github.com/snackpackgames/cosmicparade/issues/74), so an empty stock must
	# be inert rather than conjuring one.
	var realm := await _realm()
	for hex in [Vector2i(-2, 0), Vector2i(2, 0)]:
		var shrine := ShrinePlacement.new(
			load("res://data/realm/shrine/plain_shrine.tres"), 0, [hex] as Array[Vector2i]
		)
		realm.state.place(shrine)
	assert_eq(realm.state.shrines_in_stock(), 0)

	realm.lift_from_stock()

	assert_false(realm.carry.is_carrying())
	assert_eq(realm.state.placements.size(), 3, "the Altar and the two shrines")


func test_a_shrine_lifted_from_stock_lands_as_a_shrine_placement() -> void:
	var realm := await _realm()
	realm.lift_from_stock()
	realm.carry.aim(Vector2i(2, 0))
	realm.carry.place()
	assert_eq(realm.state.shrine_placements().size(), 1)
	assert_eq(realm.state.shrines_in_stock(), 1)


func test_a_shrine_placed_from_stock_arrives_with_an_empty_vessel() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/75 -- a shrine projects what is
	# offered, and nothing has been offered yet.
	var realm := await _realm()
	realm.lift_from_stock()
	realm.carry.place()
	assert_eq(realm.state.shrine_zones().size(), 0)


func test_the_altar_can_be_lifted_and_cancelled_back() -> void:
	var realm := await _realm()
	realm.cursor.aim_at(Vector2i.ZERO)
	realm.lift_under_cursor()
	assert_true(realm.carry.is_carrying())
	assert_null(realm.state.occupant_at(Vector2i.ZERO))

	realm.carry.cancel()

	assert_not_null(realm.state.occupant_at(Vector2i.ZERO))
	assert_eq(realm.state.altar_placement.hexes.size(), 3)


func test_there_is_no_way_to_stow_the_altar() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/77 — "must have one" is
	# enforced by the absence of a destination, not by a check.
	var realm := await _realm()
	assert_eq(realm.state.shrines_in_stock(), 2)
	realm.cursor.aim_at(Vector2i.ZERO)
	realm.lift_under_cursor()
	realm.carry.cancel()
	assert_eq(realm.state.shrines_in_stock(), 2)
