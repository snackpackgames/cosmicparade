class_name DomainProjection
extends ZoneSource
## An authored zone source: a fixed domain projected at a fixed reach over the hexes a piece
## occupies. It holds only immutable data, so every placeable shares the one authored reference.
## https://github.com/snackpackgames/cosmicparade/issues/127

@export var domain: Domain.Kind = Domain.Kind.FOREST

## The radius of the discs the zone is grown from. 1 is the baseline.
@export var reach: int = 1


func zone_over(hexes: Array[Vector2i]) -> InfluenceZone:
	return InfluenceZone.project(domain, hexes, reach)
