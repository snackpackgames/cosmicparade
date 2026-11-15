class_name RealmBoard
extends Node3D
## The realm board: one hex space per coordinate it was given.

var zones: Array[InfluenceZone] = []

var _spaces: Dictionary = {}
var _material: ShaderMaterial


func build(hexes: Array[Vector2i]) -> void:
	_material = BoardMaterial.create()
	for hex in hexes:
		_add_space(hex)


## Reconciles the spaces with a new extent: adds what arrived, frees what went away, and leaves
## every other space the same node, so growth costs work proportional to the change.
## https://github.com/snackpackgames/cosmicparade/issues/59
func set_hexes(hexes: Array[Vector2i]) -> void:
	var wanted: Dictionary = {}
	for hex in hexes:
		wanted[hex] = true
		if not _spaces.has(hex):
			_add_space(hex)
	for hex: Vector2i in _spaces.keys():
		if not wanted.has(hex):
			_spaces[hex].queue_free()
			_spaces.erase(hex)


func rebuild(changed_hexes: Array[Vector2i]) -> void:
	for hex in changed_hexes:
		var space: HexSpace = _spaces.get(hex)
		if space != null:
			space.set_depth(Elevation.depth_at(hex, zones))


func hex_space(hex: Vector2i) -> HexSpace:
	return _spaces.get(hex)


func _add_space(hex: Vector2i) -> void:
	if _material == null:
		_material = BoardMaterial.create()
	var space := HexSpace.new()
	space.configure(hex, _material)
	add_child(space)
	_spaces[hex] = space
	space.set_depth(Elevation.depth_at(hex, zones))
