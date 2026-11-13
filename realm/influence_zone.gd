class_name InfluenceZone
extends RefCounted
## A single influence zone: one domain over a set of hexes.

var domain: Domain.Kind
var _hexes: Dictionary = {}


func _init(zone_domain: Domain.Kind, hexes: Array[Vector2i]) -> void:
	domain = zone_domain
	for hex in hexes:
		_hexes[hex] = true


func covers(hex: Vector2i) -> bool:
	return _hexes.has(hex)


func hex_count() -> int:
	return _hexes.size()
