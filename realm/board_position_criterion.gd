class_name BoardPositionCriterion
extends PlacementCriterion
## Every hex of the footprint must be an edge hex, or must not be. Checked once at placement:
## a wing can make an edge hex interior later, which is accepted.
## https://github.com/snackpackgames/cosmicparade/issues/55

@export var require_edge: bool = true


func failing_hexes(context: PlacementContext) -> Array[Vector2i]:
	var failing: Array[Vector2i] = []
	for hex in context.occupied:
		if context.is_edge_hex(hex) != require_edge:
			failing.append(hex)
	return failing


func describe() -> String:
	return "On the edge" if require_edge else "Away from the edge"
