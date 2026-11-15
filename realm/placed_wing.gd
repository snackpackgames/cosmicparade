class_name PlacedWing
extends RefCounted
## One wing attached to the board: an authored shape, a rotation in 60-degree steps, and the
## anchor its offsets are measured from.
## https://github.com/snackpackgames/cosmicparade/issues/61

var shape: WingShape
var steps: int
var anchor: Vector2i


func _init(wing_shape: WingShape, rotation_steps: int, wing_anchor: Vector2i) -> void:
	shape = wing_shape
	steps = rotation_steps
	anchor = wing_anchor


func hexes() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for offset in shape.rotated_offsets(steps):
		result.append(anchor + offset)
	return result
