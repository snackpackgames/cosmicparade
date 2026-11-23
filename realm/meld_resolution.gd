class_name MeldResolution
extends RefCounted
## What one hex shows, derived and stored nowhere: the entries that fired, in match order, the
## depth beneath them, and whether the hex is at its burgeon ceiling.
## https://github.com/snackpackgames/cosmicparade/issues/106
## https://github.com/snackpackgames/cosmicparade/issues/109

## Zones covering the hex, per domain — the counts `Elevation` reads, carried because the debug
## probe cannot check the depth line without them.
var zone_counts: Dictionary = {}
var matches: Array[EffectMatch] = []
## The hex's own depth: the maximum across domains, which is what the risers follow.
var depth: int = 0
var depth_domain: Domain.Kind = Domain.Kind.FOREST
var at_ceiling: bool = false
## The table's ceiling effect when `at_ceiling`, and null otherwise — including when the hex is at
## its ceiling and the table authors no ceiling effect.
var ceiling_effect: InfluenceEffect


func is_empty() -> bool:
	return zone_counts.is_empty()


## The set a region compares and the renderer draws: one effect per entry that fired, with the
## ceiling effect last when the hex is at its ceiling.
func effects() -> Array[InfluenceEffect]:
	var result: Array[InfluenceEffect] = []
	for effect_match in matches:
		result.append(effect_match.effect)
	if ceiling_effect != null:
		result.append(ceiling_effect)
	return result


## True when both hexes show the same effects. Membership only: two hexes showing the same effects
## at different intensities agree, because depth enters region identity through the ceiling effect
## alone — otherwise every riser contour would split a region, which is not the consequence
## #109 recorded. Compared by instance: Godot caches resources by path, so every read of the
## authored table yields the same `InfluenceEffect` instances. If an effect is ever instanced per
## hex to carry per-hex shader parameters, this silently reports every hex as its own region.
## https://github.com/snackpackgames/cosmicparade/issues/108
func agrees_with(other: MeldResolution) -> bool:
	var mine := effects()
	var theirs := other.effects()
	if mine.size() != theirs.size():
		return false
	for effect in mine:
		if not theirs.has(effect):
			return false
	return true
