class_name RealmBoard
extends Node3D
## The realm board: one hex space per coordinate it was given.

var zones: Array[InfluenceZone] = []

var _spaces: Dictionary = {}
var _material: ShaderMaterial


func build(hexes: Array[Vector2i]) -> void:
	_material = BoardMaterial.create()
	for hex in hexes:
		var space := HexSpace.new()
		space.configure(hex, _material)
		add_child(space)
		_spaces[hex] = space
		space.set_depth(Elevation.depth_at(hex, zones))


func rebuild(changed_hexes: Array[Vector2i]) -> void:
	for hex in changed_hexes:
		var space: HexSpace = _spaces.get(hex)
		if space != null:
			space.set_depth(Elevation.depth_at(hex, zones))


func hex_space(hex: Vector2i) -> HexSpace:
	return _spaces.get(hex)
