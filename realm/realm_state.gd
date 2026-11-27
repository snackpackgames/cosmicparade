class_name RealmState
extends RefCounted
## The committed board: the realm's extent plus the pieces standing on it. The only thing stored
## twice is the occupancy index, which is a lookup table over `placements` and is rebuilt by
## every mutation. Zones are recomputed from the placements on every call and nothing caches
## them, the same ruling height got.
## https://github.com/snackpackgames/cosmicparade/issues/59

const STARTING_SHRINE_CAPACITY := 2

var geometry: RealmGeometry
var placements: Array[BoardPlacement] = []

## How many shrines the player owns. Stock is derived from it, never stored.
## https://github.com/snackpackgames/cosmicparade/issues/74
var shrine_capacity: int = STARTING_SHRINE_CAPACITY

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


## The zones of shrines alone, fed ones only. `zones()` still returns everything, because
## fixtures raise ground like anything else; this is the narrower question the Altar asks.
## https://github.com/snackpackgames/cosmicparade/issues/30
## https://github.com/snackpackgames/cosmicparade/issues/79
func shrine_zones() -> Array[InfluenceZone]:
	var result: Array[InfluenceZone] = []
	for placement in vessel_placements():
		var zone := placement.zone()
		if zone != null:
			result.append(zone)
	return result


func vessel_placements() -> Array[BoardPlacement]:
	var result: Array[BoardPlacement] = []
	for placement in placements:
		if placement.can_hold_offering():
			result.append(placement)
	return result


## Shrines the player owns but has not placed. Derived: capacity minus what stands on the board.
## https://github.com/snackpackgames/cosmicparade/issues/74
func shrines_in_stock() -> int:
	return shrine_capacity - vessel_placements().size()


## Stands the Altar on the origin in its default orientation, which exists at every core radius
## and after every wing, so no coordinate is authored.
## https://github.com/snackpackgames/cosmicparade/issues/53
## https://github.com/snackpackgames/cosmicparade/issues/77
func place_altar(altar: Altar) -> void:
	var hexes := Footprint.occupied(altar.shape, 0, Vector2i.ZERO, altar.anchor)
	place(BoardPlacement.new(altar, 0, hexes))


## True when the Altar's footprint has a hex on this wing and a hex off it. #53 relocates a wing
## with its contents and hands a straddling *furniture* footprint back to the player; the Altar
## has no destination to be returned to, so the lift is refused instead — a second named cause on
## the refusal a disconnecting lift already earns. An Altar wholly aboard travels with the wing,
## and one wholly off it never notices. The question lives here rather than on RealmGeometry
## because geometry knows nothing of placements and this asks about both.
## https://github.com/snackpackgames/cosmicparade/issues/53
## https://github.com/snackpackgames/cosmicparade/issues/77
func altar_straddles_wing(wing_index: int) -> bool:
	if wing_index < 0 or wing_index >= geometry.wings.size():
		return false
	var wing_hexes := _as_set(geometry.wings[wing_index].hexes())
	var aboard := false
	var ashore := false
	for hex in altar_hexes():
		if wing_hexes.has(hex):
			aboard = true
		else:
			ashore = true
	return aboard and ashore


## What the Altar reads from the shrines reaching it, derived afresh and never stored. Empty when
## no Altar stands.
## https://github.com/snackpackgames/cosmicparade/issues/79
func altar_reading() -> AltarReading:
	return AltarReading.of(altar_hexes(), shrine_zones())


## The Altar's footprint: the first placement whose piece reads influence, or `[]` when none
## stands. Derived on every call, so it follows the Altar when it is relocated; a stored index
## went stale there once. Reports and does not assert: "every realm has one" holds by the absence
## of an Altar stock entry, not by a guard here.
## https://github.com/snackpackgames/cosmicparade/pull/102
## https://github.com/snackpackgames/cosmicparade/issues/128
func altar_hexes() -> Array[Vector2i]:
	for placement in placements:
		if placement.piece.reads_influence():
			return placement.hexes
	return []


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
