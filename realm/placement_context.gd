class_name PlacementContext
extends RefCounted
## The board as a candidate placement would leave it: the committed state, the hexes the
## candidate would occupy, and every zone including the candidate's own. Criteria read the board
## as it will be with the piece on it.
## https://github.com/snackpackgames/cosmicparade/issues/41

var state: RealmState
var occupied: Array[Vector2i]
var zones: Array[InfluenceZone]


func _init(
	realm_state: RealmState, candidate_hexes: Array[Vector2i], all_zones: Array[InfluenceZone]
) -> void:
	state = realm_state
	occupied = candidate_hexes
	zones = all_zones


func has_hex(hex: Vector2i) -> bool:
	return state.geometry.has_hex(hex)


func is_edge_hex(hex: Vector2i) -> bool:
	return state.geometry.is_edge_hex(hex)


func depth_at(hex: Vector2i) -> int:
	return Elevation.depth_at(hex, zones)


func zone_count(domain: Domain.Kind, hex: Vector2i) -> int:
	var count := 0
	for zone in zones:
		if zone.domain == domain and zone.covers(hex):
			count += 1
	return count


func occupant_at(hex: Vector2i) -> FurniturePlacement:
	return state.occupant_at(hex)
