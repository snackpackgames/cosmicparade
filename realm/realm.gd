class_name Realm
extends Node3D
## Placeholder realm scene, reached with F6. Camera and lighting are stubs like the title
## screen's. One path runs the whole verb: the cursor's targeted hex goes to the carry, the carry
## announces what that target would do, and the board previews the ground it would make, valid
## or refused. Commit is the only write.
## https://github.com/snackpackgames/cosmicparade/issues/31
## https://github.com/snackpackgames/cosmicparade/issues/54
##
## DEBUG ONLY: F8 lifts a placeholder stool from "inventory", F9 swells the board, F10 hands the
## player a wing to site and F11 lifts the wing under the cursor. All stand in for systems that do
## not exist yet (the inventory, adr/0011, and what buys a Swell), and `lift_from_inventory`,
## `swell`, `attach_wing` and `lift_wing_under_cursor` are the seams those will attach to.

signal piece_returned(piece: Furniture)
## Emitted on lifting a piece whose requirements nothing on the realm satisfies. Not a refusal:
## the lift still happens.
## https://github.com/snackpackgames/cosmicparade/issues/62
signal nothing_satisfies(criteria: Array[PlacementCriterion])

const DEBUG_PIECE := preload("res://data/realm/furniture/mushroom_stool.tres")
const DEBUG_WING := preload("res://data/realm/wing_shape/disc.tres")

var state := RealmState.new(RealmGeometry.new())

# Every coordinate the preview has touched since the carry began, so ending it puts back
# exactly what it disturbed.
var _touched: Dictionary = {}
var _inventory_piece: Furniture
# The wing in hand, kept because it is what knows which pieces it shook loose.
var _carried_wing: CarriedWing

@onready var board: RealmBoard = $RealmBoard
@onready var cursor: HexCursor = $HexCursor
@onready var carry: Carry = $Carry
@onready var view: FurnitureView = $FurnitureView
@onready var camera: Camera3D = $Camera3D
@onready var refusal: RefusalDisplay = $RefusalDisplay
@onready var spill: SpillDisplay = $SpillDisplay
@onready var requirements: RequirementList = %RequirementList


func _ready() -> void:
	board.build(state.geometry.hexes())
	carry.configure(state)
	carry.lifted.connect(_on_lifted)
	carry.aimed.connect(_on_aimed)
	carry.placed.connect(_on_placed.unbind(1))
	carry.cancelled.connect(_on_cancelled)
	cursor.targeted_hex_changed.connect(carry.aim)
	_refresh_view()


func lift_from_inventory(piece: Furniture) -> void:
	if carry.is_carrying():
		return
	_inventory_piece = piece
	carry.lift(CarriedFurniture.new(piece, piece.anchor, null), cursor.targeted_hex)
	_announce_if_impossible(piece, piece.anchor)


## Lifts the piece standing under the cursor, with the cursor's hex as the grab hex so the piece
## does not jump in the hand.
func lift_under_cursor() -> void:
	if carry.is_carrying():
		return
	var origin := state.occupant_at(cursor.targeted_hex)
	if origin == null:
		return
	var offsets := Footprint.offsets_for(origin.furniture.shape)
	var grab_offset: Vector2i = offsets[origin.hexes.find(cursor.targeted_hex)]
	_inventory_piece = null
	_touch(origin.zone().coordinates())
	carry.lift(CarriedFurniture.new(origin.furniture, grab_offset, origin), cursor.targeted_hex)
	_announce_if_impossible(origin.furniture, grab_offset)


## Hands the player a wing to site. A wing goes through the same carry furniture does, so there
## is no second verb here: only a different thing in hand.
## https://github.com/snackpackgames/cosmicparade/issues/54
func attach_wing(shape: WingShape) -> void:
	if carry.is_carrying():
		return
	_inventory_piece = null
	_carried_wing = CarriedWing.new(shape, Vector2i.ZERO, -1)
	carry.lift(_carried_wing, cursor.targeted_hex)


## Lifts the wing under the cursor, with its contents. Refused outright when the lift would leave
## the board in two patches, because wings chain and `adr/0001`'s rock is one object.
func lift_wing_under_cursor() -> void:
	if carry.is_carrying():
		return
	var index := state.geometry.wing_index_at(cursor.targeted_hex)
	if index < 0 or not state.geometry.can_lift_wing(index):
		return
	var wing := state.geometry.wings[index]
	# What the wing is about to take away stops holding up ground, so the hexes its pieces
	# covered need rebuilding whether or not the wing lands back near them.
	for placement in state.placements_touching(wing.hexes()):
		_touch(placement.zone().coordinates())
	_inventory_piece = null
	_carried_wing = CarriedWing.new(wing.shape, cursor.targeted_hex, index)
	carry.lift(_carried_wing, cursor.targeted_hex)
	board.zones = state.zones()
	board.set_hexes(state.geometry.hexes())
	_rebuild_touched()


## Grows the board one step and floods the new ground with the influence already spilling into it.
## https://github.com/snackpackgames/cosmicparade/issues/59
func swell() -> void:
	var arrived := state.geometry.swell()
	if arrived.is_empty():
		return
	board.zones = state.zones()
	board.set_hexes(state.geometry.hexes())
	board.rebuild(arrived)
	_refresh_view()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var hex: Variant = cursor.hex_under_pointer(camera, event.position)
		if hex != null:
			cursor.aim_at(hex)
	elif _is_target_press(event):
		cursor.step(Input.get_vector(
			"realm_target_left", "realm_target_right", "realm_target_forward", "realm_target_back"
		))
	elif event.is_action_pressed("realm_lift_or_place"):
		if carry.is_carrying():
			carry.place()
		else:
			lift_under_cursor()
	elif event.is_action_pressed("realm_cancel"):
		carry.cancel()
	elif event.is_action_pressed("realm_rotate"):
		_rotate()
	elif OS.is_debug_build() and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F8:
			lift_from_inventory(DEBUG_PIECE)
		elif event.keycode == KEY_F9:
			swell()


# Rotating while idle over a piece lifts it, turned one step. Furniture only, never a wing:
# every hex past radius 5 belongs to a wing, so a stray rotate would pick up the ground.
func _rotate() -> void:
	if not carry.is_carrying():
		lift_under_cursor()
	if carry.is_carrying():
		carry.rotate_once()


func _is_target_press(event: InputEvent) -> bool:
	for action in ["realm_target_left", "realm_target_right",
			"realm_target_forward", "realm_target_back"]:
		if event.is_action_pressed(action):
			return true
	return false


# The sweep is a function of the committed board, which cannot change during a carry, so it runs
# once on lift and not per frame. The piece is already detached, so a lifted piece's own hexes
# count as free.
func _announce_if_impossible(piece: Furniture, grab_offset: Vector2i) -> void:
	var survey := PlacementRules.survey(piece, grab_offset, state)
	if not survey.unsatisfiable.is_empty():
		nothing_satisfies.emit(survey.unsatisfiable)


func _on_lifted(carried: Carried) -> void:
	refusal.clear()
	spill.clear()
	requirements.show_requirements(carried.describe_requirements())


func _on_aimed(hexes: Array[Vector2i], verdict: PlacementVerdict) -> void:
	var zones := state.zones()
	var candidate := carry.carried.zone_at(carry.target, carry.orientation)
	if candidate == null:
		# A wing projects nothing, so there is no candidate zone to compose in and nothing to
		# spill past the rim: it is ground, and the ground it would add is drawn on carry end.
		spill.clear()
	else:
		_touch(candidate.coordinates())
		zones.append(candidate)
		spill.show_spill(candidate, state.geometry)
	board.zones = zones
	_rebuild_touched()
	view.show_placements(state.placements, zones)
	view.show_ghost(hexes, verdict.allowed, zones)
	if verdict.allowed:
		refusal.clear()
		requirements.mark_failing([] as Array[PlacementCriterion])
	else:
		refusal.mark(verdict.failing_hexes, zones)
		requirements.mark_failing(verdict.failing_criteria)


func _on_placed() -> void:
	var returned: Array[Furniture] = []
	if _carried_wing != null:
		returned = _carried_wing.displaced
	_on_carry_ended()
	for piece in returned:
		piece_returned.emit(piece)


func _on_carry_ended() -> void:
	_inventory_piece = null
	if _carried_wing != null:
		# A wing move changes the board's extent and takes its furniture with it, so every zone
		# may have moved; the spaces themselves are reconciled from the geometry.
		for placement in state.placements:
			_touch(placement.zone().coordinates())
		_carried_wing = null
	board.zones = state.zones()
	board.set_hexes(state.geometry.hexes())
	_rebuild_touched()
	_touched.clear()
	view.clear_ghost()
	refusal.clear()
	spill.clear()
	requirements.hide_requirements()
	_refresh_view()


func _on_cancelled() -> void:
	var returned := _inventory_piece
	_on_carry_ended()
	if returned != null:
		piece_returned.emit(returned)


func _touch(coordinates: Array[Vector2i]) -> void:
	for hex in coordinates:
		_touched[hex] = true


func _rebuild_touched() -> void:
	var hexes: Array[Vector2i] = []
	hexes.assign(_touched.keys())
	board.rebuild(hexes)


func _refresh_view() -> void:
	view.show_placements(state.placements, state.zones())
