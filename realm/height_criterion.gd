class_name HeightCriterion
extends PlacementCriterion
## Every hex of the footprint must sit within a range of depth. Expressed in depth, 0-4, not in
## world units: depth is the integer the rule produces, and height is a presentation detail.
## https://github.com/snackpackgames/cosmicparade/issues/55

@export var min_depth: int = 0
@export var max_depth: int = Elevation.MAX_DEPTH


func failing_hexes(context: PlacementContext) -> Array[Vector2i]:
	var failing: Array[Vector2i] = []
	for hex in context.occupied:
		var depth := context.depth_at(hex)
		if depth < min_depth or depth > max_depth:
			failing.append(hex)
	return failing


func describe() -> String:
	if max_depth >= Elevation.MAX_DEPTH:
		return "Height >= %d" % min_depth
	if min_depth <= 0:
		return "Height <= %d" % max_depth
	return "Height %d-%d" % [min_depth, max_depth]
