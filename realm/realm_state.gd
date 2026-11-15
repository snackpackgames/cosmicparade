class_name RealmState
extends RefCounted
## The committed board: the realm's extent plus the pieces standing on it. The only thing stored
## twice is the occupancy index, which is a lookup table over `placements` and is rebuilt by
## every mutation. Zones are recomputed from the placements on every call and nothing caches
## them, the same ruling height got.
## https://github.com/snackpackgames/cosmicparade/issues/59

var geometry: RealmGeometry
var placements: Array[FurniturePlacement] = []

# Which piece stands on a hex, keyed by hex. Footprints never overlap, so one piece per hex.
var _occupants: Dictionary = {}


func _init(realm_geometry: RealmGeometry) -> void:
	geometry = realm_geometry


## One zone per placement, derived afresh. Never stored.
func zones() -> Array[InfluenceZone]:
	var result: Array[InfluenceZone] = []
	for placement in placements:
		result.append(placement.zone())
	return result


## The piece standing on this hex, or null. Answers for every hex of a footprint.
func occupant_at(hex: Vector2i) -> FurniturePlacement:
	return _occupants.get(hex)


func place(placement: FurniturePlacement) -> void:
	placements.append(placement)
	for hex in placement.hexes:
		_occupants[hex] = placement


func remove(placement: FurniturePlacement) -> void:
	placements.erase(placement)
	for hex in placement.hexes:
		if _occupants.get(hex) == placement:
			_occupants.erase(hex)


## The pieces that lie wholly inside the given hexes.
func placements_within(hexes: Array[Vector2i]) -> Array[FurniturePlacement]:
	var wanted := _as_set(hexes)
	var result: Array[FurniturePlacement] = []
	for placement in placements:
		var inside := true
		for hex in placement.hexes:
			inside = inside and wanted.has(hex)
		if inside:
			result.append(placement)
	return result


## The pieces that overlap the given hexes at all.
func placements_touching(hexes: Array[Vector2i]) -> Array[FurniturePlacement]:
	var wanted := _as_set(hexes)
	var result: Array[FurniturePlacement] = []
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
