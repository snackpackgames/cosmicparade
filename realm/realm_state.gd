class_name RealmState
extends RefCounted
## The committed board: the realm's extent plus the pieces standing on it. The only thing stored
## twice is the occupancy index, which is a lookup table over `placements` and is rebuilt by
## every mutation. Zones are recomputed from the placements on every call and nothing caches
## them, the same ruling height got.
## https://github.com/snackpackgames/cosmicparade/issues/59

## How many shrines the realm owns. Rises only on the two ring Swells, to 4, and never again.
## Capacity lives here and the adherent balance does not: capacity is a property of the realm,
## while adherents are earned in the parade and spent here.
## https://github.com/snackpackgames/cosmicparade/issues/76
## https://github.com/snackpackgames/cosmicparade/issues/80
const STARTING_SHRINE_CAPACITY := 2

var geometry: RealmGeometry
var placements: Array[BoardPlacement] = []
var shrine_capacity := STARTING_SHRINE_CAPACITY

# Which piece stands on a hex, keyed by hex. One index over furniture, shrines and the Altar
# alike: footprints never overlap is one rule, not three.
# https://github.com/snackpackgames/cosmicparade/issues/51
var _occupants: Dictionary = {}


func _init(realm_geometry: RealmGeometry) -> void:
	geometry = realm_geometry


## One zone per placement that projects one, derived afresh. Never stored. A piece that
## projects nothing is absent from the tally rather than a zero entry in it — #37's depth rule
## counts zones, so an empty entry would be miscounted as coverage.
## https://github.com/snackpackgames/cosmicparade/issues/37
## https://github.com/snackpackgames/cosmicparade/issues/75
func zones() -> Array[InfluenceZone]:
	var result: Array[InfluenceZone] = []
	for placement in placements:
		var zone := placement.zone()
		if zone != null:
			result.append(zone)
	return result


## What the player holds in hand: one shrine per point of capacity, minus the ones standing on
## the board. Derived, never stored — there is no inventory object to desynchronise.
## https://github.com/snackpackgames/cosmicparade/issues/74
func shrines_in_stock() -> int:
	return shrine_capacity - shrine_placements().size()


## The zones of the fed shrines alone — the narrower question the Altar asks. `zones()` keeps
## returning everything, because #30 has fixtures raising ground like anything else, so
## elevation must keep counting shrines. Giving `InfluenceZone` a source field instead was
## rejected: it would make a derived object carry provenance nothing else wants.
## https://github.com/snackpackgames/cosmicparade/issues/30
## https://github.com/snackpackgames/cosmicparade/issues/79
func shrine_zones() -> Array[InfluenceZone]:
	var result: Array[InfluenceZone] = []
	for placement in shrine_placements():
		var zone := placement.zone()
		if zone != null:
			result.append(zone)
	return result


## Every shrine on the board, fed or empty.
func shrine_placements() -> Array[ShrinePlacement]:
	var result: Array[ShrinePlacement] = []
	for placement in placements:
		if placement is ShrinePlacement:
			result.append(placement)
	return result


## The piece standing on this hex, or null. Answers for every hex of a footprint.
func occupant_at(hex: Vector2i) -> BoardPlacement:
	return _occupants.get(hex)


func place(placement: BoardPlacement) -> void:
	placements.append(placement)
	for hex in placement.hexes:
		_occupants[hex] = placement


func remove(placement: BoardPlacement) -> void:
	placements.erase(placement)
	for hex in placement.hexes:
		if _occupants.get(hex) == placement:
			_occupants.erase(hex)


## The pieces that lie wholly inside the given hexes.
func placements_within(hexes: Array[Vector2i]) -> Array[BoardPlacement]:
	var wanted := _as_set(hexes)
	var result: Array[BoardPlacement] = []
	for placement in placements:
		var inside := true
		for hex in placement.hexes:
			inside = inside and wanted.has(hex)
		if inside:
			result.append(placement)
	return result


## The pieces that overlap the given hexes at all.
func placements_touching(hexes: Array[Vector2i]) -> Array[BoardPlacement]:
	var wanted := _as_set(hexes)
	var result: Array[BoardPlacement] = []
	for placement in placements:
		for hex in placement.hexes:
			if wanted.has(hex):
				result.append(placement)
				break
	return result


func _as_set(hexes: Array[Vector2i]) -> Dictionary:
	var hex_set: Dictionary = {}
	for hex in hexes:
		hex_set[hex] = true
	return hex_set
