extends GutTest
## A single hex space: a prism from its own top face down to the board base.

const SCENE := preload("res://realm/hex_space.tscn")


func _space(hex: Vector2i, depth: int) -> HexSpace:
	var space: HexSpace = add_child_autofree(SCENE.instantiate())
	space.configure(hex, BoardMaterial.create())
	space.set_depth(depth)
	return space


# The scene carries the structure, so the two nodes and the layer exist before anything
# configures the space. https://github.com/snackpackgames/cosmicparade/issues/148
func test_the_scene_brings_its_own_body_and_mesh() -> void:
	var space: HexSpace = add_child_autofree(SCENE.instantiate())
	assert_not_null(space.get_node_or_null("MeshInstance3D"), "the mesh is authored, not built")
	assert_not_null(space.get_node_or_null("CollisionShape3D"), "and so is the shape's node")
	assert_eq(space.collision_layer, 1, "realm_space is bit 1, set in the inspector")
	assert_eq(space.collision_mask, 0, "the board detects nothing")


# The editor preview generates a mesh, a shape and a material onto nodes the scene owns, so
# all three are dropped before a save writes the file and rebuilt after. Authored geometry
# could drift from the height the runtime derives (`adr/0014`), so none of it may land on disk.
# https://github.com/snackpackgames/cosmicparade/issues/148
func test_nothing_it_generates_survives_into_a_saved_scene() -> void:
	var space := _space(Vector2i.ZERO, 2)
	var mesh_instance: MeshInstance3D = space.get_node("MeshInstance3D")
	space._clear_generated_state()
	assert_null(mesh_instance.mesh, "no mesh is written")
	assert_null(mesh_instance.material_override, "no material either")
	assert_null(space.get_node("CollisionShape3D").shape, "nor the collision prism")


func test_the_geometry_comes_back_at_the_depth_it_had_before_the_save() -> void:
	var space := _space(Vector2i.ZERO, 2)
	var mesh_instance: MeshInstance3D = space.get_node("MeshInstance3D")
	var material: Material = mesh_instance.material_override
	space._clear_generated_state()
	space._restore_generated_state()
	assert_not_null(mesh_instance.mesh, "the mesh is rebuilt")
	assert_eq(mesh_instance.material_override, material, "the same material comes back")
	assert_almost_eq(space.top_height(), Elevation.height_for_depth(2), 0.0001, "same depth")


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


# Godot's front faces are clockwise: a visible triangle's right-hand normal points AWAY from
# the side it is seen from, opposite to its shading normal. `CylinderMesh` with six radial
# segments -- the same shape, authored by Godot -- winds all 36 of its faces that way. Wound the
# other way every face of the prism is culled and a hex reads as a shell with its lid missing,
# which is what it did. Heights and the collision prism are unaffected by winding, so no other
# test here can see this. https://github.com/snackpackgames/cosmicparade/issues/150
func test_every_face_is_wound_so_it_is_not_culled() -> void:
	var space := _space(Vector2i(2, -1), 3)
	var mesh: ArrayMesh = space.get_node("MeshInstance3D").mesh
	var arrays: Array = mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	assert_null(arrays[Mesh.ARRAY_INDEX], "unindexed, so vertices are read three at a time")
	assert_eq(vertices.size(), 54, "six triangles of top face and twelve of wall")
	for triangle in range(0, vertices.size(), 3):
		var right_hand := (
			(vertices[triangle + 1] - vertices[triangle])
			. cross(vertices[triangle + 2] - vertices[triangle])
			. normalized()
		)
		assert_lt(
			right_hand.dot(normals[triangle]),
			0.0,
			"triangle %d is wound inside out" % (triangle / 3)
		)


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
