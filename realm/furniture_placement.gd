class_name FurniturePlacement
extends RefCounted
## One piece standing on the board: the authored piece, the orientation it was placed at, and
## the hexes it occupies. The occupied set is stored rather than recomputed from a target and a
## grab offset, because it is the thing the board cares about and what every criterion reads.
## https://github.com/snackpackgames/cosmicparade/issues/56

var furniture: Furniture
var orientation: int
var hexes: Array[Vector2i]


func _init(piece: Furniture, piece_orientation: int, occupied: Array[Vector2i]) -> void:
	furniture = piece
	orientation = piece_orientation
	hexes = occupied


## Derived on demand, never stored: one zone whatever the footprint.
## https://github.com/snackpackgames/cosmicparade/issues/59
func zone() -> InfluenceZone:
	return InfluenceZone.project(furniture.domain, hexes, furniture.zone_radius)
