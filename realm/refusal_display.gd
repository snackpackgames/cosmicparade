class_name RefusalDisplay
extends Node3D
## PLACEHOLDER GEOMETRY. Marks the hexes a refused target fails on, one flat slab per hex on its
## top face, and nothing else: the board stays quiet until a target fails. The marks carry no
## collision, so they never shadow the cursor's ray. What marks look like is art direction.
## https://github.com/snackpackgames/cosmicparade/issues/62

const MARK_HEIGHT := 0.04
const MARK_LIFT := 0.03
const MARK_TINT := Color(1.0, 0.25, 0.25, 0.6)

var _marked: Array[Vector2i] = []
var _material: StandardMaterial3D
var _mesh: CylinderMesh


func mark(hexes: Array[Vector2i], zones: Array[InfluenceZone]) -> void:
	clear()
	for hex in hexes:
		var instance := MeshInstance3D.new()
		instance.mesh = _slab()
		instance.material_override = _tint()
		var at := HexCoordinates.center_of(hex)
		at.y = Elevation.height_at(hex, zones) + MARK_LIFT
		instance.position = at
		add_child(instance)
		_marked.append(hex)


func clear() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_marked.clear()


func marked_hexes() -> Array[Vector2i]:
	return _marked.duplicate()


func _slab() -> CylinderMesh:
	if _mesh == null:
		_mesh = CylinderMesh.new()
		_mesh.radial_segments = 6
		_mesh.rings = 1
		_mesh.top_radius = HexCoordinates.corner_offsets()[0].length() * 0.85
		_mesh.bottom_radius = _mesh.top_radius
		_mesh.height = MARK_HEIGHT
	return _mesh


func _tint() -> StandardMaterial3D:
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.albedo_color = MARK_TINT
		_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return _material
