class_name RefusalDisplay
extends Node3D
## PLACEHOLDER GEOMETRY. Marks the hexes a refused target fails on, one flat slab per hex on that
## hex's top face. It marks nothing else: the board stays quiet until a target fails, and the
## failing requirements are marked on the piece, unpaired. Marks carry no collision, so they never
## shadow the cursor's ray. How a refusal looks is art direction.
## https://github.com/snackpackgames/cosmicparade/issues/62

const MARK_COLOR := Color(1.0, 0.25, 0.25, 0.6)
const MARK_RADIUS := 0.8
const MARK_THICKNESS := 0.04
const MARK_LIFT := 0.03

var _marks: Dictionary = {}
var _mesh: CylinderMesh
var _material: StandardMaterial3D


func mark(hexes: Array[Vector2i], zones: Array[InfluenceZone]) -> void:
	clear()
	for hex in hexes:
		var instance := MeshInstance3D.new()
		instance.mesh = _slab()
		instance.material_override = _tint()
		var position := HexCoordinates.center_of(hex)
		position.y = Elevation.height_at(hex, zones) + MARK_LIFT
		instance.position = position
		add_child(instance)
		_marks[hex] = instance


func clear() -> void:
	for instance: MeshInstance3D in _marks.values():
		remove_child(instance)
		instance.queue_free()
	_marks.clear()


func marked_hexes() -> Array[Vector2i]:
	var hexes: Array[Vector2i] = []
	hexes.assign(_marks.keys())
	return hexes


func _slab() -> CylinderMesh:
	if _mesh == null:
		_mesh = CylinderMesh.new()
		_mesh.radial_segments = 6
		_mesh.rings = 1
		_mesh.top_radius = MARK_RADIUS
		_mesh.bottom_radius = MARK_RADIUS
		_mesh.height = MARK_THICKNESS
	return _mesh


func _tint() -> StandardMaterial3D:
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.albedo_color = MARK_COLOR
		_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return _material
