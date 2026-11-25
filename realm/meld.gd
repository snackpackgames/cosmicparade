class_name Meld
extends RefCounted
## Meld resolution: the influence effects a hex shows, derived from the zones covering it and the
## authored table on every call. A `static func` over `(hex, zones, table)` holding no board
## reference, exactly as `Elevation.depth_at` and `RealmState.zones()` do, so removing furniture
## changes the answer with no invalidation path to maintain. Answers for any coordinate including
## the void; clipping stays at consumption.
## https://github.com/snackpackgames/cosmicparade/issues/106
## https://github.com/snackpackgames/cosmicparade/issues/107


static func resolve(
	hex: Vector2i, zones: Array[InfluenceZone], table: InfluenceEffectTable
) -> MeldResolution:
	var resolution := MeldResolution.new()
	resolution.zone_counts = Elevation.zone_counts(hex, zones)
	var depths := Elevation.depths_by_domain(hex, zones)

	var depth_domains: Array = depths.keys()
	depth_domains.sort()
	for domain: int in depth_domains:
		if domain == depth_domains[0] or depths[domain] > resolution.depth:
			resolution.depth = depths[domain]
			resolution.depth_domain = domain as Domain.Kind

	var remaining: Dictionary = {}
	for domain: int in depths:
		remaining[domain] = true

	while true:
		var best := -1
		var best_size := 0
		for index in table.entries.size():
			var entry := table.entries[index]
			if entry.claims_within(remaining) and entry.domains.size() > best_size:
				best = index
				best_size = entry.domains.size()
		if best < 0:
			break
		var winner := table.entries[best]
		resolution.matches.append(_match_for(best, winner, depths))
		for domain: int in winner.domains:
			remaining.erase(domain)

	resolution.at_ceiling = resolution.depth == Elevation.MAX_DEPTH
	if resolution.at_ceiling:
		resolution.ceiling_effect = table.ceiling_effect
	return resolution


static func _match_for(index: int, entry: InfluenceEffectEntry, depths: Dictionary) -> EffectMatch:
	var effect_match := EffectMatch.new()
	effect_match.entry_index = index
	effect_match.domains.assign(entry.domains)
	effect_match.effect = entry.effect
	var ordered: Array[int] = []
	ordered.assign(entry.domains)
	ordered.sort()
	effect_match.intensity = -1
	for domain in ordered:
		if depths[domain] > effect_match.intensity:
			effect_match.intensity = depths[domain]
			effect_match.intensity_domain = domain as Domain.Kind
	return effect_match


## The region of agreeing hexes around `hex`, flood-filled across neighbours whose effects agree
## with it. Null when nothing covers `hex`. Terminates on its own: a hex nothing covers resolves
## empty, and an empty resolution never agrees with a non-empty one, so the frontier cannot leave
## the zones' coverage. Answers for coordinates in the void like any other.
static func region_at(
	hex: Vector2i, zones: Array[InfluenceZone], table: InfluenceEffectTable
) -> MeldRegion:
	var seed_resolution := resolve(hex, zones, table)
	if seed_resolution.is_empty():
		return null
	var members: Array[Vector2i] = [hex]
	var visited: Dictionary = {hex: true}
	var frontier: Array[Vector2i] = [hex]
	while not frontier.is_empty():
		var current: Vector2i = frontier.pop_back()
		for neighbor in HexCoordinates.neighbors(current):
			if visited.has(neighbor):
				continue
			visited[neighbor] = true
			if resolve(neighbor, zones, table).agrees_with(seed_resolution):
				members.append(neighbor)
				frontier.append(neighbor)
	return MeldRegion.new(seed_resolution.effects(), members)


## Every region the zones produce, each covered hex in exactly one. Candidates are the union of the
## zones' coordinates: a hex no zone covers shows nothing and belongs to no region, which is also
## what keeps the walk finite over an unbounded plane. Answers for off-board coordinates too, since
## clipping to the board stays at consumption.
static func regions(
	zones: Array[InfluenceZone], table: InfluenceEffectTable
) -> Array[MeldRegion]:
	var result: Array[MeldRegion] = []
	var assigned: Dictionary = {}
	for zone in zones:
		for hex in zone.coordinates():
			if assigned.has(hex):
				continue
			var region := region_at(hex, zones, table)
			for member in region.hexes:
				assigned[member] = true
			result.append(region)
	return result
