class_name AltarReading
extends RefCounted
## What the Altar reads from the shrines around it: per domain, how many shrines project a zone
## covering at least one of its hexes. Each shrine counts once however many hexes it reaches, so
## the triangle-three is a reach advantage and never a multiplier. Derived on demand, never
## stored, because offerings expire across parades.
## https://github.com/snackpackgames/cosmicparade/issues/79

var _counts: Dictionary = {}


static func of(hexes: Array[Vector2i], shrine_zones: Array[InfluenceZone]) -> AltarReading:
	var reading := AltarReading.new()
	for zone in shrine_zones:
		for hex in hexes:
			if zone.covers(hex):
				reading._counts[zone.domain] = reading._counts.get(zone.domain, 0) + 1
				break
	return reading


func count_for(domain: Domain.Kind) -> int:
	return _counts.get(domain, 0)


func domains_present() -> Array[Domain.Kind]:
	var result: Array[Domain.Kind] = []
	for domain: Domain.Kind in _counts:
		result.append(domain)
	return result


func is_empty() -> bool:
	return _counts.is_empty()
