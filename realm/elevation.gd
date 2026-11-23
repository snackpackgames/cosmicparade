class_name Elevation
extends RefCounted
## The elevation rule: depth per domain, maximum across domains, height from depth.
## The per-domain reads are additive; `adr/0014` is unchanged by them.

const MAX_DEPTH := 4
const STEP_RATIO := 0.35


## The zones covering `hex`, tallied per domain. Height reads the maximum of the depths derived
## from these and influence effects read each domain's own, so the tally is shared.
## https://github.com/snackpackgames/cosmicparade/issues/113
static func zone_counts(hex: Vector2i, zones: Array[InfluenceZone]) -> Dictionary:
	var counts: Dictionary = {}
	for zone in zones:
		if zone.covers(hex):
			counts[zone.domain] = counts.get(zone.domain, 0) + 1
	return counts


## The one place the `count - 1` rule lives: burgeon is a domain overlapping itself, so a lone zone
## raises nothing.
## https://github.com/snackpackgames/cosmicparade/issues/113
static func depth_for_count(count: int) -> int:
	return mini(MAX_DEPTH, maxi(0, count - 1))


## Depth per domain at `hex`. Height takes the maximum of these; an influence effect takes the
## depth of its own domains.
## https://github.com/snackpackgames/cosmicparade/issues/113
static func depths_by_domain(hex: Vector2i, zones: Array[InfluenceZone]) -> Dictionary:
	var depths: Dictionary = {}
	var counts := zone_counts(hex, zones)
	for domain: int in counts:
		depths[domain] = depth_for_count(counts[domain] as int)
	return depths


static func depth_at(hex: Vector2i, zones: Array[InfluenceZone]) -> int:
	var depth := 0
	for domain_depth: int in depths_by_domain(hex, zones).values():
		depth = maxi(depth, domain_depth)
	return depth


static func height_for_depth(depth: int) -> float:
	return depth * STEP_RATIO * HexCoordinates.CIRCUMRADIUS


static func height_at(hex: Vector2i, zones: Array[InfluenceZone]) -> float:
	return height_for_depth(depth_at(hex, zones))
