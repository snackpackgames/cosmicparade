class_name Carried
extends RefCounted
## Everything the carry state machine needs from the thing in hand. Subclasses: CarriedPiece,
## for anything that stands on the board, and CarriedWing, for the board itself. Wings are not
## a second verb because they answer this.
## https://github.com/snackpackgames/cosmicparade/issues/54


## The hexes the thing would occupy with its grab hex on the target.
func hexes_at(_target: Vector2i, _orientation: int) -> Array[Vector2i]:
	return []


## How many distinct orientations a rotate steps through before wrapping.
func orientation_count() -> int:
	return 1


## The orientation it carries when lifted, or -1 when it has none of its own (it came from
## inventory, so the carry's sticky orientation applies).
func own_orientation() -> int:
	return -1


func verdict_at(_target: Vector2i, _orientation: int, _state: RealmState) -> PlacementVerdict:
	return PlacementVerdict.new(false)


func zone_at(_target: Vector2i, _orientation: int) -> InfluenceZone:
	return null


## Takes the thing off the board, so its footprint and its influence are gone for the carry.
func detach(_state: RealmState) -> void:
	pass


## Writes the thing to the board at a target. The only write a carry makes.
func commit(_target: Vector2i, _orientation: int, _state: RealmState) -> void:
	pass


## Puts the thing back exactly where `detach` took it from, if it came from the board.
func restore(_state: RealmState) -> void:
	pass


func describe_requirements() -> Array[PlacementCriterion]:
	return []
