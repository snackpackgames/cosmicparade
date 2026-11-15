class_name ClearanceCriterion
extends PlacementCriterion
## No other piece may stand within `distance` of any hex of the footprint. Returns the blocking
## hexes, not the footprint's, so they can be marked. The piece's own hexes never block it, and
## off-board hexes count as clear because nothing is there.
## https://github.com/snackpackgames/cosmicparade/issues/55

@export var distance: int = 1


func failing_hexes(context: PlacementContext) -> Array[Vector2i]:
	var own: Dictionary = {}
	for hex in context.occupied:
		own[hex] = true
	var blocking: Dictionary = {}
	for hex in context.occupied:
		for nearby in HexCoordinates.disc(hex, distance):
			if not own.has(nearby) and context.occupant_at(nearby) != null:
				blocking[nearby] = true
	var failing: Array[Vector2i] = []
	failing.assign(blocking.keys())
	return failing


func describe() -> String:
	return "Clear within %d" % distance
