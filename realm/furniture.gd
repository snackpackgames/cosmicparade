class_name Furniture
extends BoardPiece
## One authored furniture piece: a board piece that also carries the domain it projects and how
## far that influence reaches. What a piece projects is a property of the piece and never of
## where it sits.
## https://github.com/snackpackgames/cosmicparade/issues/51
## https://github.com/snackpackgames/cosmicparade/issues/52

@export var domain: Domain.Kind = Domain.Kind.FOREST

## The radius of the discs its zone is grown from. 1 is the baseline.
@export var zone_radius: int = 1


func zone_for(hexes: Array[Vector2i]) -> InfluenceZone:
	return InfluenceZone.project(domain, hexes, zone_radius)
