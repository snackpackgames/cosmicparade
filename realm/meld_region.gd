class_name MeldRegion
extends RefCounted
## A maximal contiguous run of hexes whose influence effects agree. Carries no provenance: the
## effect set already names what is there, and two combinations authored to the same effect are
## one region that could not name its domains anyway.
## https://github.com/snackpackgames/cosmicparade/issues/106
## https://github.com/snackpackgames/cosmicparade/issues/108

var effects: Array[InfluenceEffect] = []
var hexes: Array[Vector2i] = []


func _init(region_effects: Array[InfluenceEffect], region_hexes: Array[Vector2i]) -> void:
	effects = region_effects
	hexes = region_hexes


func size() -> int:
	return hexes.size()


func contains(hex: Vector2i) -> bool:
	return hexes.has(hex)


## The hexes whose six neighbours are all in this region — `adr/0008`'s biome fill.
func interior() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for hex in hexes:
		if _is_surrounded(hex):
			result.append(hex)
	return result


## The hexes with at least one neighbour outside it — `adr/0008`'s feature spawning.
func boundary() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for hex in hexes:
		if not _is_surrounded(hex):
			result.append(hex)
	return result


func _is_surrounded(hex: Vector2i) -> bool:
	for neighbor in HexCoordinates.neighbors(hex):
		if not hexes.has(neighbor):
			return false
	return true
