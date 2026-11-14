class_name WingShape
extends GameData
## One authored wing figure: the hexes it covers as offsets from its anchor, and how many of
## its six rotations are distinct. The orientation count is authored, not computed.
## https://github.com/snackpackgames/cosmicparade/issues/61

@export var shape_name: String = ""
@export var offsets: Array[Vector2i] = []
@export var distinct_orientations: int = 1


func rotated_offsets(steps: int) -> Array[Vector2i]:
	var turned: Array[Vector2i] = []
	for offset in offsets:
		turned.append(HexCoordinates.rotate(offset, steps))
	return turned
