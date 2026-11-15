class_name CarriedFurniture
extends Carried
## A furniture piece in hand: six orientations, pivoting on the grab hex. `origin` is the
## placement it was lifted from, or null when it arrived from inventory.
## https://github.com/snackpackgames/cosmicparade/issues/56

const ORIENTATIONS := 6

var furniture: Furniture
var grab_offset: Vector2i
var origin: FurniturePlacement


func _init(piece: Furniture, grabbed: Vector2i, lifted_from: FurniturePlacement) -> void:
	furniture = piece
	grab_offset = grabbed
	origin = lifted_from


func hexes_at(target: Vector2i, orientation: int) -> Array[Vector2i]:
	return Footprint.occupied(furniture.shape, orientation, target, grab_offset)


func orientation_count() -> int:
	return ORIENTATIONS


func own_orientation() -> int:
	return -1 if origin == null else origin.orientation


func verdict_at(target: Vector2i, orientation: int, state: RealmState) -> PlacementVerdict:
	return PlacementRules.verdict(furniture, orientation, target, grab_offset, state)


func zone_at(target: Vector2i, orientation: int) -> InfluenceZone:
	return PlacementRules.zone_for(furniture, orientation, target, grab_offset)


func detach(state: RealmState) -> void:
	if origin != null:
		state.remove(origin)


func commit(target: Vector2i, orientation: int, state: RealmState) -> void:
	state.place(FurniturePlacement.new(furniture, orientation, hexes_at(target, orientation)))


func restore(state: RealmState) -> void:
	if origin != null:
		state.place(origin)


func describe_requirements() -> Array[PlacementCriterion]:
	return furniture.criteria
