class_name Elevation
extends RefCounted
## The elevation rule: depth per domain, maximum across domains, height from depth.

const MAX_DEPTH := 4
const STEP_RATIO := 0.35


static func depth_at(hex: Vector2i, zones: Array[InfluenceZone]) -> int:
	var zone_counts: Dictionary = {}
	for zone in zones:
		if zone.covers(hex):
			zone_counts[zone.domain] = zone_counts.get(zone.domain, 0) + 1
	var depth := 0
	for count: int in zone_counts.values():
		depth = maxi(depth, mini(MAX_DEPTH, maxi(0, count - 1)))
	return depth
