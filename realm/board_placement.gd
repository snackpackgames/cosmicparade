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

## This placeable's own zone source: the piece's authored one, or a per-placement copy of it when
## the component declares itself mutable. Null when the piece authors none.
var _source: ZoneSource


func _init(
	board_piece: BoardPiece,
	piece_orientation: int,
	occupied: Array[Vector2i],
	source: ZoneSource = null
) -> void:
	piece = board_piece
	orientation = piece_orientation
	hexes = occupied
	if source != null:
		_source = source
	elif piece.zone_source != null:
		_source = piece.zone_source.for_placement()


## The same piece standing somewhere else, carrying whatever per-placement state it holds. The
## source travels by identity, so a fed vessel stays fed and rearranging stays free (adr/0009).
func relocated(new_orientation: int, new_hexes: Array[Vector2i]) -> BoardPlacement:
	return BoardPlacement.new(piece, new_orientation, new_hexes, _source)


## Derived on demand, never stored: one zone whatever the footprint, and `null` for a piece that
## projects nothing. Resolved from the piece's one zone source, so the board stays ignorant of
## what is standing on it.
## https://github.com/snackpackgames/cosmicparade/issues/59
func zone() -> InfluenceZone:
	if _source == null:
		return null
	return _source.zone_over(hexes)


## Whether this placeable is a vessel, fed or not. Forwarded to its own component; false when it
## carries none.
## https://github.com/snackpackgames/cosmicparade/issues/135
func can_hold_offering() -> bool:
	return _source != null and _source.can_hold_offering()


func holds_offering() -> bool:
	return _source != null and _source.holds_offering()


func offer(fruit: Fruit) -> void:
	if _source != null:
		_source.accept_offering(fruit)


func empty_vessel() -> void:
	if _source != null:
		_source.empty_vessel()
