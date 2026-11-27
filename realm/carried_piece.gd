class_name CarriedPiece
extends Carried
## A board piece in hand, as a thin adapter over the placeable itself: the thing being carried
## *is* the placement, lifted off the board or built unplaced for a lift from inventory, plus the
## hex it was grabbed by. Six orientations, pivoting on that grab hex. A placeable with no hexes
## stands nowhere yet, and that is the whole of "it came from stock" — unplaced is derived, never
## stored. One carried type for furniture, shrines and the Altar alike — there is no second
## placement path and nothing in the carry state machine knows which it is holding.
## https://github.com/snackpackgames/cosmicparade/issues/56
## https://github.com/snackpackgames/cosmicparade/issues/74
## https://github.com/snackpackgames/cosmicparade/issues/77
## https://github.com/snackpackgames/cosmicparade/issues/127
## https://github.com/snackpackgames/cosmicparade/issues/131

const ORIENTATIONS := 6

var placeable: BoardPlacement

## Where on its own footprint the piece was taken hold of. Carry-only: a placement standing on
## the board has no use for it, so it stays here rather than moving onto the placeable.
## https://github.com/snackpackgames/cosmicparade/issues/131
var grab_offset: Vector2i


func _init(carried_placeable: BoardPlacement, grabbed: Vector2i) -> void:
	placeable = carried_placeable
	grab_offset = grabbed


func hexes_at(target: Vector2i, orientation: int) -> Array[Vector2i]:
	return Footprint.occupied(placeable.piece.shape, orientation, target, grab_offset)


func orientation_count() -> int:
	return ORIENTATIONS


## The placeable's own orientation once it stands somewhere, and -1 while it does not, so the
## carry's sticky orientation applies to anything lifted from inventory.
func own_orientation() -> int:
	return placeable.orientation if _stands_on_the_board() else -1


func verdict_at(target: Vector2i, orientation: int, state: RealmState) -> PlacementVerdict:
	return PlacementRules.verdict(placeable.piece, orientation, target, grab_offset, state)


## Null for a piece that projects nothing, which the carry already tolerates — a wing answers
## the same way, and for the same reason.
## https://github.com/snackpackgames/cosmicparade/issues/77
func zone_at(target: Vector2i, orientation: int) -> InfluenceZone:
	return PlacementRules.zone_for(placeable.piece, orientation, target, grab_offset)


## Taken off the board only when it is standing there; a placeable built for a lift from
## inventory is on no board to leave. It keeps its own hexes either way, which is what makes
## `restore` free: the pose it was lifted from is still written on it.
func detach(state: RealmState) -> void:
	if _stands_on_the_board():
		state.remove(placeable)


## Replaces the pose rather than mutating the placement it was handed, so the lifted placement is
## never edited where it lay and the adapter needs no remembered original. The replacement
## carries whatever per-placement state the original held by identity, so a fed vessel stays fed
## (adr/0009). One path for every piece type: nothing here asks where it came from or what it is.
## https://github.com/snackpackgames/cosmicparade/issues/127
## https://github.com/snackpackgames/cosmicparade/issues/131
func commit(target: Vector2i, orientation: int, state: RealmState) -> void:
	placeable = placeable.relocated(orientation, hexes_at(target, orientation))
	state.place(placeable)


## Puts it back exactly as it was lifted, which is unchanged. Nothing to write for a placeable
## that was never on the board.
func restore(state: RealmState) -> void:
	if _stands_on_the_board():
		state.place(placeable)


func describe_requirements() -> Array[PlacementCriterion]:
	return placeable.piece.criteria


# Derived from having hexes and from nothing else: a placeable built for a lift from inventory
# has none until a commit gives it some.
# https://github.com/snackpackgames/cosmicparade/issues/127
func _stands_on_the_board() -> bool:
	return not placeable.hexes.is_empty()
