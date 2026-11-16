class_name ShrinePlacement
extends BoardPlacement
## A shrine standing on the board, and the offering in its vessel right now. A piece knows what
## it projects as a type; a placement knows what it is projecting at this moment. An empty vessel
## projects nothing at all, so the tally never sees an entry for it.
## https://github.com/snackpackgames/cosmicparade/issues/75

var offering: Fruit


func zone() -> InfluenceZone:
	if offering == null:
		return null
	return InfluenceZone.project(offering.domain, hexes, Shrine.ZONE_RADIUS)
