class_name LevelFootprintCriterion
extends PlacementCriterion
## The whole footprint must sit at one depth. A property of the footprint as a whole, so it
## fails on every occupied hex rather than on any single one. Vacuously true at size one.
## https://github.com/snackpackgames/cosmicparade/issues/55


func failing_hexes(context: PlacementContext) -> Array[Vector2i]:
	if context.occupied.is_empty():
		return [] as Array[Vector2i]
	var depth := context.depth_at(context.occupied[0])
	for hex in context.occupied:
		if context.depth_at(hex) != depth:
			return context.occupied.duplicate()
	return [] as Array[Vector2i]


func describe() -> String:
	return "Level ground"
