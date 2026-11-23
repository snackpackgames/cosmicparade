class_name InfluenceEffectEntry
extends GameData
## One or more domains and the influence effect they produce. The domains are a set: order here is
## irrelevant, so Forest-then-Flame and Flame-then-Forest are the same entry.
## https://github.com/snackpackgames/cosmicparade/issues/107
## https://github.com/snackpackgames/cosmicparade/issues/113

## `Domain.Kind` values. `Array[int]` rather than `Array[Domain.Kind]` because GDScript has no
## enum-typed arrays.
@export var domains: Array[int] = []
@export var effect: InfluenceEffect


## True when every domain this entry needs is among `available`, whose keys are `Domain.Kind`
## values. An entry claiming no domains claims nothing: the empty set is a subset of every set, so
## without that case greedy matching would never terminate.
func claims_within(available: Dictionary) -> bool:
	if domains.is_empty():
		return false
	for domain: int in domains:
		if not available.has(domain):
			return false
	return true
