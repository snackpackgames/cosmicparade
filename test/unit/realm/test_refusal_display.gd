extends GutTest
## The board's half of a refusal: marks on the failing hexes, nothing else.


func test_a_fresh_display_marks_nothing() -> void:
	var display: RefusalDisplay = autofree(RefusalDisplay.new())
	assert_eq(display.marked_hexes(), [] as Array[Vector2i])


func test_marking_shows_exactly_the_hexes_it_was_given() -> void:
	var display: RefusalDisplay = add_child_autofree(RefusalDisplay.new())
	display.mark([Vector2i.ZERO, Vector2i(1, 0)] as Array[Vector2i], [] as Array[InfluenceZone])
	var marked := display.marked_hexes()
	marked.sort()
	assert_eq(marked, [Vector2i.ZERO, Vector2i(1, 0)] as Array[Vector2i])


func test_marking_again_replaces_the_previous_marks() -> void:
	var display: RefusalDisplay = add_child_autofree(RefusalDisplay.new())
	display.mark([Vector2i.ZERO] as Array[Vector2i], [] as Array[InfluenceZone])
	display.mark([Vector2i(2, 0)] as Array[Vector2i], [] as Array[InfluenceZone])
	assert_eq(display.marked_hexes(), [Vector2i(2, 0)] as Array[Vector2i])


func test_clearing_removes_every_mark() -> void:
	var display: RefusalDisplay = add_child_autofree(RefusalDisplay.new())
	display.mark([Vector2i.ZERO] as Array[Vector2i], [] as Array[InfluenceZone])
	display.clear()
	assert_eq(display.marked_hexes(), [] as Array[Vector2i])


func test_a_mark_is_not_solid_so_it_never_shadows_the_cursor_ray() -> void:
	var display: RefusalDisplay = add_child_autofree(RefusalDisplay.new())
	display.mark([Vector2i.ZERO] as Array[Vector2i], [] as Array[InfluenceZone])
	assert_gt(display.get_child_count(), 0)
	for child in display.get_children():
		assert_false(child is CollisionObject3D, "marks carry no collision")
