class_name HexSpace
extends StaticBody3D
## A single hex space: a prism from its own top face down to the board base.

const BASE_Y := -2.0
const UV_SCALE := 0.5

var hex: Vector2i

var _mesh_instance: MeshInstance3D
var _collision_shape: CollisionShape3D
var _top_height := 0.0


func configure(space_hex: Vector2i, material: Material) -> void:
	hex = space_hex
	collision_layer = 1
	collision_mask = 0
	position = HexCoordinates.center_of(hex)
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.name = "MeshInstance3D"
	_mesh_instance.material_override = material
	add_child(_mesh_instance)
	_collision_shape = CollisionShape3D.new()
	_collision_shape.name = "CollisionShape3D"
	add_child(_collision_shape)


func set_depth(depth: int) -> void:
	_top_height = Elevation.height_for_depth(depth)
	_mesh_instance.mesh = _build_mesh()
	var shape := ConvexPolygonShape3D.new()
	var points := PackedVector3Array()
	for offset in HexCoordinates.corner_offsets():
		points.append(offset + Vector3(0.0, _top_height, 0.0))
		points.append(offset + Vector3(0.0, BASE_Y, 0.0))
	shape.points = points
	_collision_shape.shape = shape


func top_height() -> float:
	return _top_height


func _build_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var corners := HexCoordinates.corner_offsets()
	var top := Vector3(0.0, _top_height, 0.0)
	for i in 6:
		var next := (i + 1) % 6
		_add_vertex(tool, top, Vector3.UP)
		_add_vertex(tool, corners[next] + top, Vector3.UP)
		_add_vertex(tool, corners[i] + top, Vector3.UP)
		var normal := ((corners[i] + corners[next]) * 0.5).normalized()
		var base := Vector3(0.0, BASE_Y, 0.0)
		_add_vertex(tool, corners[i] + top, normal)
		_add_vertex(tool, corners[next] + top, normal)
		_add_vertex(tool, corners[next] + base, normal)
		_add_vertex(tool, corners[i] + top, normal)
		_add_vertex(tool, corners[next] + base, normal)
		_add_vertex(tool, corners[i] + base, normal)
	return tool.commit()


# UVs come from world position so the tessera pattern runs across the board.
func _add_vertex(tool: SurfaceTool, vertex: Vector3, normal: Vector3) -> void:
	var world := vertex + HexCoordinates.center_of(hex)
	tool.set_normal(normal)
	tool.set_uv(Vector2(world.x, world.z) * UV_SCALE)
	tool.add_vertex(vertex)
