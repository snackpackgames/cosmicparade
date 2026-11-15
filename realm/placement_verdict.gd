class_name PlacementVerdict
extends RefCounted
## The judgement on one target: whether it is allowed, which hexes are the problem, and which
## criteria failed. The two lists are unpaired on purpose — the board marks hexes, the piece
## marks requirements, and nothing says which hex broke which requirement.
## https://github.com/snackpackgames/cosmicparade/issues/62

var allowed: bool
var failing_hexes: Array[Vector2i]
var failing_criteria: Array[PlacementCriterion]


func _init(
	is_allowed: bool,
	hexes: Array[Vector2i] = [],
	criteria: Array[PlacementCriterion] = []
) -> void:
	allowed = is_allowed
	failing_hexes = hexes
	failing_criteria = criteria
