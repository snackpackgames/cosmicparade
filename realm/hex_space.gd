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
## Opening this scene on its own draws a flat hex, so there is something to look at. The mesh,
## the shape and the material are all generated, so none of them may reach the `.tscn`: a hex's
## height is derived from the influence on it (`adr/0014`) and an authored copy could drift from
## what the runtime makes. `_notification` drops them around a save for exactly that reason.

const BASE_Y := -2.0
const UV_SCALE := 0.5

var hex: Vector2i

var _top_height := 0.0
var _depth := 0
var _material: Material

@onready var _mesh_instance: MeshInstance3D = %MeshInstance3D
@onready var _collision_shape: CollisionShape3D = %CollisionShape3D


## Draws a flat hex, in the board's placeholder material, when `hex_space.tscn` is itself the
## scene being edited. A hex on a board is never the edited scene -- `realm.tscn` is -- so the
## board stays the only thing that configures its own spaces.
## https://github.com/snackpackgames/cosmicparade/issues/148
func _ready() -> void:
	if Engine.is_editor_hint() and get_tree().edited_scene_root == self:
		configure(Vector2i.ZERO, BoardMaterial.create())
		set_depth(0)


## Keeps the generated geometry out of any scene file that holds this node. Godot sends these
## two notifications around an editor save for this purpose: the mesh, shape and material go
## away before the file is written and come back after, so the `.tscn` on disk carries the empty
## body it declares and the viewport still shows a hex.
func _notification(what: int) -> void:
	if not Engine.is_editor_hint():
		return
	if what == NOTIFICATION_EDITOR_PRE_SAVE:
		_clear_generated_state()
	elif what == NOTIFICATION_EDITOR_POST_SAVE:
		_restore_generated_state()


func configure(space_hex: Vector2i, material: Material) -> void:
	hex = space_hex
	position = HexCoordinates.center_of(hex)
	_material = material
	_mesh_instance.material_override = material


func set_depth(depth: int) -> void:
	_depth = depth
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


## Drops everything this node generates, so a scene save writes the empty body the `.tscn`
## declares rather than a snapshot of one depth.
func _clear_generated_state() -> void:
	_mesh_instance.mesh = null
	_mesh_instance.material_override = null
	_collision_shape.shape = null


## Puts back what `_clear_generated_state` dropped, at the depth this space already had, so the
## viewport looks the same after a save as before it.
func _restore_generated_state() -> void:
	_mesh_instance.material_override = _material
	set_depth(_depth)


func _build_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var corners := HexCoordinates.corner_offsets()
	var top := Vector3(0.0, _top_height, 0.0)
	# Clockwise, which is what Godot culls against: every triangle below is ordered so its
	# right-hand normal points away from the side the face is seen from, opposite to the
	# shading normal. https://github.com/snackpackgames/cosmicparade/issues/150
	for i in 6:
		var next := (i + 1) % 6
		_add_vertex(tool, top, Vector3.UP)
		_add_vertex(tool, corners[i] + top, Vector3.UP)
		_add_vertex(tool, corners[next] + top, Vector3.UP)
		var normal := ((corners[i] + corners[next]) * 0.5).normalized()
		var base := Vector3(0.0, BASE_Y, 0.0)
		_add_vertex(tool, corners[i] + top, normal)
		_add_vertex(tool, corners[next] + base, normal)
		_add_vertex(tool, corners[next] + top, normal)
		_add_vertex(tool, corners[i] + top, normal)
		_add_vertex(tool, corners[i] + base, normal)
		_add_vertex(tool, corners[next] + base, normal)
	return tool.commit()


# UVs come from world position so the tessera pattern runs across the board.
func _add_vertex(tool: SurfaceTool, vertex: Vector3, normal: Vector3) -> void:
	var world := vertex + HexCoordinates.center_of(hex)
	tool.set_normal(normal)
	tool.set_uv(Vector2(world.x, world.z) * UV_SCALE)
	tool.add_vertex(vertex)
