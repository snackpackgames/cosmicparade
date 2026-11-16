class_name BoardPiece
extends GameData
## One authored thing that stands on the realm board: the footprint it occupies, the hex it
## arrives under, and the gates on where it may be placed. Furniture, shrines and the Altar are
## all board pieces, and `RealmState` keeps one occupancy index over all three — footprints never
## overlap is one rule, not three.
## https://github.com/snackpackgames/cosmicparade/issues/51
## https://github.com/snackpackgames/cosmicparade/issues/74
## https://github.com/snackpackgames/cosmicparade/issues/77

@export var piece_name: String = ""
@export var shape: Footprint.Shape = Footprint.Shape.SINGLE

## Which of the shape's own offsets the piece arrives under when taken from inventory.
@export var anchor: Vector2i = Vector2i.ZERO

@export var criteria: Array[PlacementCriterion] = []


## What this piece projects over the hexes it occupies, or `null` for a piece that projects
## nothing. A null is not an empty zone: #37's depth tally must not see an entry for a piece
## that contributes none, and null is the only return that cannot be miscounted. The base
## answers for the Altar, which projects nothing at all.
## https://github.com/snackpackgames/cosmicparade/issues/37
## https://github.com/snackpackgames/cosmicparade/issues/77
func zone_for(_hexes: Array[Vector2i]) -> InfluenceZone:
	return null
