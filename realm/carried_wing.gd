class_name CarriedWing
extends Carried
## A wing in hand. Wings are not a second verb: this answers the same interface furniture does,
## and the state machine never learns it exists. What differs is that a wing *is* board, so it
## projects no influence and asks nothing of the ground — `zone_at` and `describe_requirements`
## stay the base's null and empty — and it cycles only the rotations its shape makes distinct.
## `origin_index` is the wing it was lifted from, or -1 for a wing the realm has just bought.
## https://github.com/snackpackgames/cosmicparade/issues/53
## https://github.com/snackpackgames/cosmicparade/issues/54
## https://github.com/snackpackgames/cosmicparade/issues/61

var shape: WingShape
## The hex the wing was grabbed by, in board coordinates. A wing from a Swell has no hex on the
## board to grab, so it is ignored there and the shape's anchor lands on the target.
var grab_offset: Vector2i
var origin_index: int
## The pieces lifted off because they straddled the seam, in the order they were found. Returning
## them costs nothing: https://github.com/snackpackgames/cosmicparade/issues/53
var displaced: Array[BoardPiece] = []

var _origin_anchor := Vector2i.ZERO
var _origin_steps := 0
# Where the anchor sits relative to the grab hex, in the shape's own unrotated frame, so a
# rotation in hand pivots on the grab hex the way a turning piece does.
var _anchor_offset := Vector2i.ZERO
var _travelling: Array[BoardPlacement] = []
var _straddling: Array[BoardPlacement] = []
var _detached := false


func _init(wing_shape: WingShape, grabbed: Vector2i, lifted_from: int) -> void:
	shape = wing_shape
	grab_offset = grabbed
	origin_index = lifted_from


func hexes_at(target: Vector2i, orientation: int) -> Array[Vector2i]:
	return PlacedWing.new(shape, orientation, _anchor_at(target, orientation)).hexes()


## Only the distinct rotations, so pressing rotate never shows the same figure twice: 1 for the
## disc, 6 for the trapezoid. A deliberate break from furniture's six steps, whose justification
## was art facing — a wing has no art.
## https://github.com/snackpackgames/cosmicparade/issues/61
func orientation_count() -> int:
	return shape.distinct_orientations


func own_orientation() -> int:
	return -1 if origin_index < 0 else _origin_steps


func verdict_at(target: Vector2i, orientation: int, state: RealmState) -> PlacementVerdict:
	if state.geometry.can_attach(shape, orientation, _anchor_at(target, orientation)):
		return PlacementVerdict.new(true)
	# The whole figure is what is wrong with the siting, and a wing has no criteria, so the
	# requirement list has nothing to mark.
	# https://github.com/snackpackgames/cosmicparade/issues/62
	return PlacementVerdict.new(false, hexes_at(target, orientation))


## Takes the wing off the board with everything standing wholly on it. A piece straddling the
## seam is lifted off into `displaced` rather than forbidding the move: displacement, not a new
## constraint. A lift that would leave the board in two patches is refused and changes nothing —
## the realm asks first, so this is the guard that keeps a refusal from half-emptying the board.
func detach(state: RealmState) -> void:
	if origin_index < 0 or not state.geometry.can_lift_wing(origin_index):
		return
	var wing := state.geometry.wings[origin_index]
	_origin_anchor = wing.anchor
	_origin_steps = wing.steps
	_anchor_offset = HexCoordinates.rotate(wing.anchor - grab_offset, -wing.steps)
	var wing_hexes := wing.hexes()
	_travelling = state.placements_within(wing_hexes)
	for placement in state.placements_touching(wing_hexes):
		if not _travelling.has(placement):
			_straddling.append(placement)
			displaced.append(placement.piece)
	for placement in _travelling:
		state.remove(placement)
	for placement in _straddling:
		state.remove(placement)
	state.geometry.lift_wing(origin_index)
	_detached = true


## Attaches the wing and re-places what rode on it. Hexes are never lost: relocation is not a
## refund, so the board keeps the same count it had.
func commit(target: Vector2i, orientation: int, state: RealmState) -> void:
	if origin_index >= 0 and not _detached:
		return
	var anchor := _anchor_at(target, orientation)
	if state.geometry.attach(shape, orientation, anchor).is_empty():
		return
	for placement in _travelling:
		state.place(_carried_along(placement, anchor, orientation))
	_travelling.clear()
	_straddling.clear()
	_detached = false


## Cancel means nothing happened, so the straddlers go back too.
func restore(state: RealmState) -> void:
	if not _detached:
		return
	state.geometry.attach(shape, _origin_steps, _origin_anchor)
	for placement in _travelling:
		state.place(placement)
	for placement in _straddling:
		state.place(placement)
	_travelling.clear()
	_straddling.clear()
	displaced.clear()
	_detached = false


func _anchor_at(target: Vector2i, orientation: int) -> Vector2i:
	return target + HexCoordinates.rotate(_anchor_offset, orientation)


# The same offsets relative to the wing, read in the shape's unrotated frame and laid down again
# in the new one: the ground turned, so what stands on it turns with it.
func _carried_along(
	placement: BoardPlacement, anchor: Vector2i, orientation: int
) -> BoardPlacement:
	var hexes: Array[Vector2i] = []
	for hex in placement.hexes:
		var canonical := HexCoordinates.rotate(hex - _origin_anchor, -_origin_steps)
		hexes.append(anchor + HexCoordinates.rotate(canonical, orientation))
	var turned := posmod(placement.orientation + orientation - _origin_steps, 6)
	return placement.relocated(turned, hexes)
