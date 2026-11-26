@tool
class_name HexSpace
extends StaticBody3D
## A single hex space: a prism from its own top face down to the board base.
##
## Authored as `hex_space.tscn`, so the two children and the `realm_space` layer are in the
## scene tree where the inspector can show them, rather than assembled in `configure`. What
## stays in code is what is derived: the extent the board draws (`adr/0015`) and this prism's
## height, which follows the influence on the hex (`adr/0014`).
## https://github.com/snackpackgames/cosmicparade/issues/148
##
## `@tool` so `RealmBoard`'s editor preview can build these
## (https://github.com/snackpackgames/cosmicparade/issues/146). It is load-bearing now rather
## than inert: the two `@onready` references below are only assigned if the editor runs `_ready`,
## and without them a previewed space would reach for a null mesh.
##
## Opening this scene on its own shows the structure and an empty body, not a hex. Drawing one
## would mean a `@tool` script writing `mesh` onto a node the scene owns, which a save would
## then bake into `hex_space.tscn` -- authored geometry that could drift from what the runtime
## derives, which is the thing `adr/0014` is for. The board preview is where hexes are looked at.

const BASE_Y := -2.0
const UV_SCALE := 0.5

var hex: Vector2i

var _top_height := 0.0

@onready var _mesh_instance: MeshInstance3D = %MeshInstance3D
@onready var _collision_shape: CollisionShape3D = %CollisionShape3D


func configure(space_hex: Vector2i, material: Material) -> void:
	hex = space_hex
	position = HexCoordinates.center_of(hex)
	_mesh_instance.material_override = material


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
