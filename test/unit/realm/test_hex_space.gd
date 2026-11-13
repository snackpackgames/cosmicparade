extends GutTest
## A single hex space: a prism from its own top face down to the board base.

func _space(hex: Vector2i, depth: int) -> HexSpace:
	var space: HexSpace = add_child_autofree(HexSpace.new())
	space.configure(hex, BoardMaterial.create())
	space.set_depth(depth)
	return space


func test_it_is_a_passive_target_on_realm_space() -> void:
	var space := _space(Vector2i.ZERO, 0)
	assert_eq(space.collision_layer, 1, "realm_space is bit 1")
	assert_eq(space.collision_mask, 0, "the board detects nothing")


func test_it_sits_at_its_hex_centre() -> void:
	var space := _space(Vector2i(2, -1), 0)
	assert_eq(space.position, HexCoordinates.center_of(Vector2i(2, -1)))


# Every hex has a body regardless of depth: a flat hex is a zero-rise column.
# https://github.com/snackpackgames/cosmicparade/issues/39
func test_a_flat_hex_still_has_a_body_with_a_top_face_at_board_level() -> void:
	var space := _space(Vector2i.ZERO, 0)
	assert_almost_eq(space.top_height(), 0.0, 0.0001)
	assert_eq(space.get_shape_owners().size(), 1)


func test_its_top_face_rises_with_its_depth() -> void:
	assert_almost_eq(_space(Vector2i.ZERO, 3).top_height(), Elevation.height_for_depth(3), 0.0001)


func test_the_collision_prism_spans_the_top_face_to_the_board_base() -> void:
	var space := _space(Vector2i.ZERO, 2)
	var shape: ConvexPolygonShape3D = space.get_node("CollisionShape3D").shape
	assert_eq(shape.points.size(), 12, "six top corners and six base corners")
	var heights: Array[float] = []
	for point: Vector3 in shape.points:
		if not heights.has(point.y):
			heights.append(point.y)
	heights.sort()
	assert_eq(heights.size(), 2)
	assert_almost_eq(heights[0], HexSpace.BASE_Y, 0.0001)
	assert_almost_eq(heights[1], Elevation.height_for_depth(2), 0.0001)


func test_the_top_face_is_level_so_the_riser_is_vertical() -> void:
	# Discrete risers, never smoothed slopes: every top corner is at the hex's
	# own height. https://github.com/snackpackgames/cosmicparade/issues/28
	var space := _space(Vector2i.ZERO, 1)
	var mesh: ArrayMesh = space.get_node("MeshInstance3D").mesh
	var vertices: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var top := Elevation.height_for_depth(1)
	for vertex: Vector3 in vertices:
		assert_true(
			is_equal_approx(vertex.y, top) or is_equal_approx(vertex.y, HexSpace.BASE_Y),
			"a vertex at y=%f is neither the top face nor the base" % vertex.y
		)


func test_changing_depth_replaces_the_geometry_rather_than_adding_to_it() -> void:
	var space := _space(Vector2i.ZERO, 1)
	var before: int = space.get_child_count()
	space.set_depth(4)
	assert_eq(space.get_child_count(), before)
	assert_almost_eq(space.top_height(), Elevation.height_for_depth(4), 0.0001)
