class_name FurnitureView
extends Node3D
## PLACEHOLDER GEOMETRY. Draws placed furniture and the carried ghost as low prisms, one per
## occupied hex, standing on that hex's top face. The authored models are art direction and
## deferred; what is real here is that furniture is a volume on the `furniture` layer
## (adr/0001) and that the ghost has no collision, so the cursor's ray never picks it.

const FURNITURE_LAYER := 2
const PRISM_HEIGHT := 0.5
const PRISM_INSET := 0.7
const ALLOWED_TINT := Color(0.4, 1.0, 0.5, 0.5)
const REFUSED_TINT := Color(1.0, 0.35, 0.35, 0.5)

var _bodies: Dictionary = {}
var _ghost: Node3D
var _material: ShaderMaterial


func show_placements(
	placements: Array[FurniturePlacement], zones: Array[InfluenceZone]
) -> void:
	for body: StaticBody3D in _bodies.values():
		remove_child(body)
		body.queue_free()
	_bodies.clear()
	if _material == null:
		_material = BoardMaterial.create()
	for placement in placements:
		var body := StaticBody3D.new()
		body.collision_layer = FURNITURE_LAYER
		body.collision_mask = 0
		_fill(body, placement.hexes, zones, _material, true)
		add_child(body)
		_bodies[placement] = body


func show_ghost(hexes: Array[Vector2i], allowed: bool, zones: Array[InfluenceZone]) -> void:
	clear_ghost()
	var tint := StandardMaterial3D.new()
	tint.albedo_color = ALLOWED_TINT if allowed else REFUSED_TINT
	tint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ghost = Node3D.new()
	_fill(_ghost, hexes, zones, tint, false)
	add_child(_ghost)


func clear_ghost() -> void:
	if _ghost == null:
		return
	remove_child(_ghost)
	_ghost.queue_free()
	_ghost = null


func body_for(placement: FurniturePlacement) -> StaticBody3D:
	return _bodies.get(placement)


# The root rides the first hex; each prism keeps its own hex's ground height relative to it.
func _fill(
	root: Node3D,
	hexes: Array[Vector2i],
	zones: Array[InfluenceZone],
	material: Material,
	solid: bool
) -> void:
	if hexes.is_empty():
		return
	var base := HexCoordinates.center_of(hexes[0])
	base.y = Elevation.height_at(hexes[0], zones)
	root.position = base
	for hex in hexes:
		var offset := HexCoordinates.center_of(hex)
		offset.y = Elevation.height_at(hex, zones)
		offset -= base
		var instance := MeshInstance3D.new()
		instance.mesh = _prism()
		instance.material_override = material
		instance.position = offset
		root.add_child(instance)
		if solid:
			var shape := CollisionShape3D.new()
			shape.shape = _prism_shape()
			shape.position = offset
			root.add_child(shape)


func _corners() -> PackedVector3Array:
	var corners := PackedVector3Array()
	for corner in HexCoordinates.corner_offsets():
		corners.append(corner * PRISM_INSET)
	return corners


func _prism_shape() -> ConvexPolygonShape3D:
	var shape := ConvexPolygonShape3D.new()
	var points := PackedVector3Array()
	for corner in _corners():
		points.append(corner)
		points.append(corner + Vector3(0.0, PRISM_HEIGHT, 0.0))
	shape.points = points
	return shape


func _prism() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var corners := _corners()
	var rise := Vector3(0.0, PRISM_HEIGHT, 0.0)
	for i in 6:
		var next := (i + 1) % 6
		_add(tool, rise, Vector3.UP)
		_add(tool, corners[next] + rise, Vector3.UP)
		_add(tool, corners[i] + rise, Vector3.UP)
		var normal := ((corners[i] + corners[next]) * 0.5).normalized()
		_add(tool, corners[i] + rise, normal)
		_add(tool, corners[next] + rise, normal)
		_add(tool, corners[next], normal)
		_add(tool, corners[i] + rise, normal)
		_add(tool, corners[next], normal)
		_add(tool, corners[i], normal)
	return tool.commit()


func _add(tool: SurfaceTool, vertex: Vector3, normal: Vector3) -> void:
	tool.set_normal(normal)
	tool.set_uv(Vector2(vertex.x, vertex.z))
	tool.add_vertex(vertex)
