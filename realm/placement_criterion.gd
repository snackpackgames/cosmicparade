class_name PlacementCriterion
extends GameData
## One gate a piece puts on where it may be placed. The five concrete criteria — height, level
## footprint, domain influence count, clearance, board position — are the whole vocabulary; a
## sixth is a design change, not a feature. Every criterion must pass on every hex of the
## footprint, and a criterion only ever refuses: it may never modify a zone, a radius or a depth.
## https://github.com/snackpackgames/cosmicparade/issues/55
##
## The base refuses nothing. The concrete criteria arrive in Phase 3, which is also where
## `context` gains its `PlacementContext` type.


## The hexes of the footprint this criterion refuses, which is none of them for the base.
func failing_hexes(_context) -> Array[Vector2i]:
	return [] as Array[Vector2i]


## One line of player-facing text naming the requirement.
func describe() -> String:
	return ""
