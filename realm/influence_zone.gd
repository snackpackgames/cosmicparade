class_name InfluenceZone
extends RefCounted
## A single influence zone: one domain over a set of hexes.

var domain: Domain.Kind
var _hexes: Dictionary = {}


func _init(zone_domain: Domain.Kind, hexes: Array[Vector2i]) -> void:
	domain = zone_domain
	for hex in hexes:
		_hexes[hex] = true


## The union of radius-`radius` discs grown from every hex the piece occupies — one zone per
## piece whatever its footprint, computed with no reference to the board. The coordinates that
## land in the void are in the set like any others; clipping happens at consumption.
## https://github.com/snackpackgames/cosmicparade/issues/52
## https://github.com/snackpackgames/cosmicparade/issues/59
static func project(domain: Domain.Kind, occupied: Array[Vector2i], radius: int) -> InfluenceZone:
	var union: Dictionary = {}
	for hex in occupied:
		for covered in HexCoordinates.disc(hex, radius):
			union[covered] = true
	var hexes: Array[Vector2i] = []
	hexes.assign(union.keys())
	return InfluenceZone.new(domain, hexes)


func covers(hex: Vector2i) -> bool:
	return _hexes.has(hex)


## Every coordinate the zone covers, the off-board part included.
func coordinates() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	result.assign(_hexes.keys())
	return result


func hex_count() -> int:
	return _hexes.size()
