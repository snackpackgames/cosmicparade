class_name Carry
extends Node
## The carry state machine: click to lift, the piece rides one targeted hex, click to place,
## cancel to go back. Validity is a property of the current target, re-evaluated on every aim and
## rotate, and placing a refused target is inert. This is the only thing that writes to the board.
## https://github.com/snackpackgames/cosmicparade/issues/54

signal lifted(carried: Carried)
signal aimed(hexes: Array[Vector2i], verdict: PlacementVerdict)
signal placed(hexes: Array[Vector2i])
signal cancelled

var carried: Carried
var orientation := 0
var target := Vector2i.ZERO

var _state: RealmState
var _verdict: PlacementVerdict
# Carry state, never board state: where a piece from inventory arrives.
# https://github.com/snackpackgames/cosmicparade/issues/56
var _last_placed_orientation := 0


func configure(state: RealmState) -> void:
	_state = state


func is_carrying() -> bool:
	return carried != null


func verdict() -> PlacementVerdict:
	return _verdict


func lift(thing: Carried, at: Vector2i) -> void:
	if is_carrying():
		return
	thing.detach(_state)
	carried = thing
	var own := thing.own_orientation()
	orientation = _last_placed_orientation if own < 0 else own
	target = at
	lifted.emit(thing)
	_evaluate()


func aim(hex: Vector2i) -> void:
	if not is_carrying():
		return
	target = hex
	_evaluate()


func rotate_once() -> void:
	if not is_carrying():
		return
	orientation = (orientation + 1) % carried.orientation_count()
	_evaluate()


## Inert while the target is refused: nothing is written and the player keeps carrying.
func place() -> bool:
	if not is_carrying() or not _verdict.allowed:
		return false
	var hexes := carried.hexes_at(target, orientation)
	carried.commit(target, orientation, _state)
	_last_placed_orientation = orientation
	_clear()
	placed.emit(hexes)
	return true


func cancel() -> void:
	if not is_carrying():
		return
	carried.restore(_state)
	_clear()
	cancelled.emit()


func _evaluate() -> void:
	_verdict = carried.verdict_at(target, orientation, _state)
	aimed.emit(carried.hexes_at(target, orientation), _verdict)


func _clear() -> void:
	carried = null
	_verdict = null
