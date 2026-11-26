class_name OfferingVessel
extends ZoneSource
## The zone source of a shrine: it projects the domain of whatever fruit it holds, at an authored
## reach. The reach is authored and shared; the contents are not, because a `.tres` is shared by
## every instance and what is in a vessel is per-placement state.
## https://github.com/snackpackgames/cosmicparade/issues/75
## https://github.com/snackpackgames/cosmicparade/issues/127
## https://github.com/snackpackgames/cosmicparade/issues/135

## The radius of the disc the offering's domain is grown into.
@export var reach: int = 2

## What the vessel holds right now. Runtime state, never authored.
var offering: Fruit


## Null when empty, never an empty zone: the depth tally counts zones, so an empty entry would be
## miscounted as coverage.
## https://github.com/snackpackgames/cosmicparade/issues/37
func zone_over(hexes: Array[Vector2i]) -> InfluenceZone:
	if offering == null:
		return null
	return InfluenceZone.project(offering.domain, hexes, reach)


func can_hold_offering() -> bool:
	return true


func holds_offering() -> bool:
	return offering != null


func accept_offering(fruit: Fruit) -> void:
	offering = fruit


func empty_vessel() -> void:
	offering = null


## The one override that makes a component per-copy: a vessel's contents change, so two placeables
## built from one authored shrine must not share it, or feeding one would feed both. The component
## decides rather than the caller, so the construction site never learns which components are
## mutable and no uniform `duplicate()` is needed.
## https://github.com/snackpackgames/cosmicparade/issues/135
func for_placement() -> ZoneSource:
	var copy := OfferingVessel.new()
	copy.reach = reach
	return copy
