class_name SpillDisplay
extends Node3D
## PLACEHOLDER GEOMETRY. Draws the part of a carried zone that falls off the rock: the
## coordinates with no hex under them, as thin rings at board level. A rim placement is legal and
## merely weaker, so this is deliberately a different node and a different shape from the refusal
## marks. The meshes carry no collision. How it looks is art direction.
## https://github.com/snackpackgames/cosmicparade/issues/59
## https://github.com/snackpackgames/cosmicparade/issues/62

const SPILL_HEIGHT := 0.02
const SPILL_TINT := Color(0.45, 0.7, 1.0, 0.35)

var _spilled: Array[Vector2i] = []
var _material: StandardMaterial3D
var _mesh: TorusMesh


func show_spill(zone: InfluenceZone, geometry: RealmGeometry) -> void:
	clear()
	for hex in zone.coordinates():
		if geometry.has_hex(hex):
			continue
		var instance := MeshInstance3D.new()
		instance.mesh = _ring()
		instance.material_override = _tint()
		instance.position = HexCoordinates.center_of(hex) + Vector3(0.0, SPILL_HEIGHT, 0.0)
		add_child(instance)
		_spilled.append(hex)


func clear() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_spilled.clear()


func spilled_hexes() -> Array[Vector2i]:
	return _spilled.duplicate()


func _ring() -> TorusMesh:
	if _mesh == null:
		var reach := HexCoordinates.corner_offsets()[0].length() * 0.7
		_mesh = TorusMesh.new()
		_mesh.outer_radius = reach
		_mesh.inner_radius = reach * 0.8
		_mesh.rings = 12
		_mesh.ring_segments = 4
	return _mesh


func _tint() -> StandardMaterial3D:
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.albedo_color = SPILL_TINT
		_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return _material
