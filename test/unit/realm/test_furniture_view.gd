extends GutTest
## Placed furniture and the carried ghost.


func _stool() -> Furniture:
	return load("res://data/realm/furniture/mushroom_stool.tres")


func _stool_placement() -> BoardPlacement:
	return BoardPlacement.new(_stool(), 0, [Vector2i.ZERO] as Array[Vector2i])


func test_it_builds_one_body_per_placement() -> void:
	var view: FurnitureView = add_child_autofree(FurnitureView.new())
	var placement := _stool_placement()
	view.show_placements([placement], [] as Array[InfluenceZone])
	assert_not_null(view.body_for(placement))


func test_a_body_sits_on_the_furniture_layer_and_detects_nothing() -> void:
	var view: FurnitureView = add_child_autofree(FurnitureView.new())
	var placement := _stool_placement()
	view.show_placements([placement], [] as Array[InfluenceZone])
	assert_eq(view.body_for(placement).collision_layer, 2)
	assert_eq(view.body_for(placement).collision_mask, 0)


func test_a_body_rides_the_height_of_the_ground_under_it() -> void:
	var view: FurnitureView = add_child_autofree(FurnitureView.new())
	var zones: Array[InfluenceZone] = [
		InfluenceZone.new(Domain.Kind.STONE, [Vector2i.ZERO] as Array[Vector2i]),
		InfluenceZone.new(Domain.Kind.STONE, [Vector2i.ZERO] as Array[Vector2i]),
	]
	var placement := _stool_placement()
	view.show_placements([placement], zones)
	assert_almost_eq(
		view.body_for(placement).position.y, Elevation.height_for_depth(1), 0.0001
	)


func test_showing_a_new_set_of_placements_drops_the_old_bodies() -> void:
	var view: FurnitureView = add_child_autofree(FurnitureView.new())
	var placement := _stool_placement()
	view.show_placements([placement], [] as Array[InfluenceZone])
	view.show_placements([] as Array[BoardPlacement], [] as Array[InfluenceZone])
	await wait_frames(1)
	assert_null(view.body_for(placement))
	assert_eq(view.get_child_count(), 0)


func test_the_ghost_has_no_collision_so_the_cursor_ray_passes_through_it() -> void:
	var view: FurnitureView = add_child_autofree(FurnitureView.new())
	view.show_ghost([Vector2i.ZERO] as Array[Vector2i], true, [] as Array[InfluenceZone])
	assert_eq(view.get_child_count(), 1)
	for node in view.get_child(0).get_children():
		assert_false(node is CollisionObject3D or node is CollisionShape3D, "not solid")


func test_clearing_the_ghost_leaves_the_placed_bodies_alone() -> void:
	var view: FurnitureView = add_child_autofree(FurnitureView.new())
	var placement := _stool_placement()
	view.show_placements([placement], [] as Array[InfluenceZone])
	view.show_ghost([Vector2i(1, 0)] as Array[Vector2i], true, [] as Array[InfluenceZone])
	view.clear_ghost()
	await wait_frames(1)
	assert_not_null(view.body_for(placement))
	assert_eq(view.get_child_count(), 1)
