class_name BoardPlacement
extends RefCounted
## One piece standing on the board: the authored piece, the orientation it was placed at, and
## the hexes it occupies. The occupied set is stored rather than recomputed from a target and a
## grab offset, because it is the thing the board cares about and what every criterion reads.
## Furniture, shrines and the Altar all stand here — the board never asks which it is.
## https://github.com/snackpackgames/cosmicparade/issues/56
## https://github.com/snackpackgames/cosmicparade/issues/74

var piece: BoardPiece
var orientation: int
var hexes: Array[Vector2i]


func _init(board_piece: BoardPiece, piece_orientation: int, occupied: Array[Vector2i]) -> void:
	piece = board_piece
	orientation = piece_orientation
	hexes = occupied


## Derived on demand, never stored: one zone whatever the footprint, and `null` for a piece that
## projects nothing. Delegated to the piece rather than branched on here, so the board stays
## ignorant of what is standing on it.
## https://github.com/snackpackgames/cosmicparade/issues/59
func zone() -> InfluenceZone:
	return piece.zone_for(hexes)
