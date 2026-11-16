extends GutTest
## The hex cursor: one targeted hex, whatever device moved it.


func test_the_cursor_starts_on_the_origin() -> void:
	assert_eq(autofree(HexCursor.new()).targeted_hex, Vector2i.ZERO)


func test_aiming_moves_the_target_and_announces_it() -> void:
	var cursor: HexCursor = add_child_autofree(HexCursor.new())
	watch_signals(cursor)
	cursor.aim_at(Vector2i(2, -1))
	assert_eq(cursor.targeted_hex, Vector2i(2, -1))
	assert_signal_emitted_with_parameters(cursor, "targeted_hex_changed", [Vector2i(2, -1)])


func test_aiming_at_the_same_hex_announces_nothing() -> void:
	var cursor: HexCursor = add_child_autofree(HexCursor.new())
	cursor.aim_at(Vector2i(2, -1))
	watch_signals(cursor)
	cursor.aim_at(Vector2i(2, -1))
	assert_signal_not_emitted(cursor, "targeted_hex_changed")


func test_every_push_resolves_to_one_of_the_six_directions() -> void:
	for degrees in 360:
		var push := Vector2.RIGHT.rotated(deg_to_rad(degrees))
		assert_true(
			HexCoordinates.DIRECTIONS.has(HexCursor.nearest_direction(push)),
			"%d degrees" % degrees
		)


func test_a_push_straight_at_a_direction_picks_that_direction() -> void:
	for direction: Vector2i in HexCoordinates.DIRECTIONS:
		var center := HexCoordinates.center_of(direction)
		assert_eq(HexCursor.nearest_direction(Vector2(center.x, center.z)), direction)


func test_a_zero_push_does_not_move_the_target() -> void:
	var cursor: HexCursor = add_child_autofree(HexCursor.new())
	cursor.step(Vector2.ZERO)
	assert_eq(cursor.targeted_hex, Vector2i.ZERO)


func test_stepping_moves_one_hex_at_a_time() -> void:
	var cursor: HexCursor = add_child_autofree(HexCursor.new())
	var center := HexCoordinates.center_of(Vector2i(1, 0))
	cursor.step(Vector2(center.x, center.z))
	assert_eq(cursor.targeted_hex, Vector2i(1, 0))
	assert_eq(HexCoordinates.distance(Vector2i.ZERO, cursor.targeted_hex), 1)


func test_the_pointer_ray_hits_realm_space_only() -> void:
	var cursor: HexCursor = add_child_autofree(HexCursor.new())
	var board: RealmBoard = add_child_autofree(RealmBoard.new())
	board.build([Vector2i.ZERO] as Array[Vector2i])
	var camera: Camera3D = add_child_autofree(Camera3D.new())
	camera.position = Vector3(0, 5, 0)
	camera.rotation_degrees = Vector3(-90, 0, 0)
	await wait_physics_frames(2)
	var viewport_center := camera.get_viewport().get_visible_rect().size / 2.0
	assert_eq(cursor.hex_under_pointer(camera, viewport_center), Vector2i.ZERO)
