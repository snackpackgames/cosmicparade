class_name CarriedPiece
extends Carried
## A board piece in hand: six orientations, pivoting on the grab hex. `origin` is the placement
## it was lifted from, or null when it arrived from stock. One carried type for furniture,
## shrines and the Altar alike — there is no second placement path and nothing in the carry
## state machine knows which it is holding.
## https://github.com/snackpackgames/cosmicparade/issues/56
## https://github.com/snackpackgames/cosmicparade/issues/74
## https://github.com/snackpackgames/cosmicparade/issues/77

const ORIENTATIONS := 6

var piece: BoardPiece
var grab_offset: Vector2i
var origin: BoardPlacement


func _init(board_piece: BoardPiece, grabbed: Vector2i, lifted_from: BoardPlacement) -> void:
	piece = board_piece
	grab_offset = grabbed
	origin = lifted_from


func hexes_at(target: Vector2i, orientation: int) -> Array[Vector2i]:
	return Footprint.occupied(piece.shape, orientation, target, grab_offset)


func orientation_count() -> int:
	return ORIENTATIONS


func own_orientation() -> int:
	return -1 if origin == null else origin.orientation


func verdict_at(target: Vector2i, orientation: int, state: RealmState) -> PlacementVerdict:
	return PlacementRules.verdict(piece, orientation, target, grab_offset, state)


## Null for a piece that projects nothing, which the carry already tolerates — a wing answers
## the same way, and for the same reason.
## https://github.com/snackpackgames/cosmicparade/issues/77
func zone_at(target: Vector2i, orientation: int) -> InfluenceZone:
	return PlacementRules.zone_for(piece, orientation, target, grab_offset)


func detach(state: RealmState) -> void:
	if origin != null:
		state.remove(origin)


func commit(target: Vector2i, orientation: int, state: RealmState) -> void:
	var hexes := hexes_at(target, orientation)
	if origin != null:
		state.place(origin.relocated(orientation, hexes))
	elif piece is Shrine:
		state.place(ShrinePlacement.new(piece, orientation, hexes))
	else:
		state.place(BoardPlacement.new(piece, orientation, hexes))


func restore(state: RealmState) -> void:
	if origin != null:
		state.place(origin)


func describe_requirements() -> Array[PlacementCriterion]:
	return piece.criteria
