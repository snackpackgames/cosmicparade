class_name ShrinePlacement
extends BoardPlacement
## A shrine standing on the board, with whatever is in its vessel right now. One vessel, one
## offering, one domain, one zone.
##
## This overrides `zone()` rather than having `Shrine` override `zone_for()`, because the
## offering is per-placement state and a `.tres` is shared by every holder of its path. The
## split is the honest one: a piece knows what it projects as a *type*, a placement knows what
## it is projecting *right now*.
## https://github.com/snackpackgames/cosmicparade/issues/75

## What is being offered, or null for an empty vessel.
var offering: Fruit


## An empty vessel projects nothing at all — no domain, no zone, nothing for #37's tally. The
## radius is 2 however full the vessel is, because #55 lets nothing modify what a piece
## projects.
## https://github.com/snackpackgames/cosmicparade/issues/37
## https://github.com/snackpackgames/cosmicparade/issues/55
## https://github.com/snackpackgames/cosmicparade/issues/75
func zone() -> InfluenceZone:
	if offering == null:
		return null
	return InfluenceZone.project(offering.domain, hexes, Shrine.ZONE_RADIUS)
