class_name SpillDisplay
extends Node3D
## PLACEHOLDER GEOMETRY. Draws the part of a carried piece's influence that falls past the board's
## edge: the coordinates of the zone with no hex under them. A rim placement is legal and merely
## weaker, so this is deliberately a different node and a different shape from the refusal's
## marks. Meshes carry no collision. How the spill looks is art direction.
## https://github.com/snackpackgames/cosmicparade/issues/59
## https://github.com/snackpackgames/cosmicparade/issues/62

const SPILL_COLOR := Color(0.45, 0.7, 1.0, 0.35)
const SPILL_RADIUS := 0.5
const SPILL_HEIGHT := 0.25

var _spill: Dictionary = {}
var _mesh: CylinderMesh
var _material: StandardMaterial3D


func show_spill(zone: InfluenceZone, geometry: RealmGeometry) -> void:
	clear()
	for coordinate in zone.coordinates():
		if geometry.has_hex(coordinate):
			continue
		var instance := MeshInstance3D.new()
		instance.mesh = _post()
		instance.material_override = _tint()
		var position := HexCoordinates.center_of(coordinate)
		position.y = SPILL_HEIGHT * 0.5
		instance.position = position
		add_child(instance)
		_spill[coordinate] = instance


func clear() -> void:
	for instance: MeshInstance3D in _spill.values():
		remove_child(instance)
		instance.queue_free()
	_spill.clear()


func spilled_hexes() -> Array[Vector2i]:
	var hexes: Array[Vector2i] = []
	hexes.assign(_spill.keys())
	return hexes


func _post() -> CylinderMesh:
	if _mesh == null:
		_mesh = CylinderMesh.new()
		_mesh.radial_segments = 12
		_mesh.rings = 1
		_mesh.top_radius = 0.0
		_mesh.bottom_radius = SPILL_RADIUS
		_mesh.height = SPILL_HEIGHT
	return _mesh


func _tint() -> StandardMaterial3D:
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.albedo_color = SPILL_COLOR
		_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return _material
