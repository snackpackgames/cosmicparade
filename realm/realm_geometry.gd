class_name RealmGeometry
extends RefCounted
## The realm board's extent, generated rather than stored: a radial core of some radius plus an
## ordered set of placed wings. The origin never moves, so placed furniture keeps its
## coordinates through every Swell. Nothing downstream knows a hex is on a wing.
## https://github.com/snackpackgames/cosmicparade/issues/50
## https://github.com/snackpackgames/cosmicparade/issues/53

const CORE_START_RADIUS := 3
const CORE_MAX_RADIUS := 5

var core_radius := CORE_START_RADIUS
var wings: Array[PlacedWing] = []

# A cache of the two generators above, rebuilt on every mutation. Never a second authority.
var _hexes: Dictionary = {}


func _init() -> void:
	_recache()


func hexes() -> Array[Vector2i]:
	var result: Array[Vector2i] = HexCoordinates.disc(Vector2i.ZERO, core_radius)
	for wing in wings:
		result.append_array(wing.hexes())
	return result


func has_hex(hex: Vector2i) -> bool:
	return _hexes.has(hex)


func is_edge_hex(hex: Vector2i) -> bool:
	if not has_hex(hex):
		return false
	for neighbor in HexCoordinates.neighbors(hex):
		if not has_hex(neighbor):
			return true
	return false


func wing_index_at(hex: Vector2i) -> int:
	for index in wings.size():
		if wings[index].hexes().has(hex):
			return index
	return -1


func rings_remaining() -> int:
	return CORE_MAX_RADIUS - core_radius


## Grows the core by one ring while rings remain, and returns the hexes that arrived. Past the
## ceiling a Swell is a wing attachment the player sites, so this adds nothing.
func swell() -> Array[Vector2i]:
	if rings_remaining() <= 0:
		return [] as Array[Vector2i]
	core_radius += 1
	_recache()
	return HexCoordinates.ring(Vector2i.ZERO, core_radius)


func can_attach(shape: WingShape, steps: int, anchor: Vector2i) -> bool:
	return _is_attachable(PlacedWing.new(shape, steps, anchor).hexes())


## Attaches the wing and returns the hexes it added, or nothing if the siting is illegal.
func attach(shape: WingShape, steps: int, anchor: Vector2i) -> Array[Vector2i]:
	var wing := PlacedWing.new(shape, steps, anchor)
	var added := wing.hexes()
	if not _is_attachable(added):
		return [] as Array[Vector2i]
	wings.append(wing)
	_recache()
	return added


## A lift is refused when it would leave the rest of the board not edge-connected: wings may
## chain, so lifting the one another hangs off would orphan hexes.
func can_lift_wing(index: int) -> bool:
	if index < 0 or index >= wings.size():
		return false
	var lifted: Dictionary = {}
	for hex in wings[index].hexes():
		lifted[hex] = true
	var remaining: Dictionary = {}
	for hex: Vector2i in _hexes:
		if not lifted.has(hex):
			remaining[hex] = true
	return _is_one_patch(remaining)


## Lifts the wing and returns the hexes it took away, or nothing if the lift is refused.
func lift_wing(index: int) -> Array[Vector2i]:
	if not can_lift_wing(index):
		return [] as Array[Vector2i]
	var removed := wings[index].hexes()
	wings.remove_at(index)
	_recache()
	return removed


func _recache() -> void:
	_hexes.clear()
	for hex in hexes():
		_hexes[hex] = true


func _is_attachable(wing_hexes: Array[Vector2i]) -> bool:
	var shares_an_edge := false
	for hex in wing_hexes:
		if has_hex(hex):
			return false
		for neighbor in HexCoordinates.neighbors(hex):
			if has_hex(neighbor):
				shares_an_edge = true
	return shares_an_edge


func _is_one_patch(hex_set: Dictionary) -> bool:
	if hex_set.is_empty():
		return true
	var unreached := hex_set.duplicate()
	var start: Vector2i = unreached.keys()[0]
	unreached.erase(start)
	var frontier: Array[Vector2i] = [start]
	var reached := 1
	while not frontier.is_empty():
		for neighbor in HexCoordinates.neighbors(frontier.pop_back()):
			if unreached.erase(neighbor):
				frontier.append(neighbor)
				reached += 1
	return reached == hex_set.size()
