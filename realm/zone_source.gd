class_name ZoneSource
extends GameData
## The component that answers what a board piece projects over the hexes it occupies. A piece
## carries at most one, in `BoardPiece.zone_source`. Every method here is a default an override
## replaces, and each is answered by the component about itself, never type-tested from outside.
## https://github.com/snackpackgames/cosmicparade/issues/127
## https://github.com/snackpackgames/cosmicparade/issues/135


## The zone projected over `_hexes`, or `null` for a source that projects nothing. A null is not
## an empty zone: the depth tally counts zones, so an empty entry would be miscounted as coverage.
## https://github.com/snackpackgames/cosmicparade/issues/37
func zone_over(_hexes: Array[Vector2i]) -> InfluenceZone:
	return null


## The component a placeable carries. `self`, because authored data is never mutated at runtime,
## so sharing the reference is safe. A component whose contents change overrides this to copy.
## https://github.com/snackpackgames/cosmicparade/issues/127
## https://github.com/snackpackgames/cosmicparade/issues/135
func for_placement() -> ZoneSource:
	return self


## Whether this source is a vessel that can be fed an offering. False by default: the question is
## answered here by the component, so callers never type-test what a piece carries.
## https://github.com/snackpackgames/cosmicparade/issues/135
func can_hold_offering() -> bool:
	return false


## Whether an offering is currently held. False by default, for the same reason.
## https://github.com/snackpackgames/cosmicparade/issues/135
func holds_offering() -> bool:
	return false


## A no-op by default so a caller may offer without first asking what it is offering to.
## https://github.com/snackpackgames/cosmicparade/issues/135
func accept_offering(_fruit: Fruit) -> void:
	pass


## A no-op by default, mirroring `accept_offering`.
## https://github.com/snackpackgames/cosmicparade/issues/135
func empty_vessel() -> void:
	pass
