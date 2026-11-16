class_name PlacementSurvey
extends RefCounted
## What a sweep over the whole board says about a piece: whether any placement satisfies it, and
## which requirements nothing on the realm satisfies even alone. `placeable == false` with an
## empty `unsatisfiable` is a real state under AND: each requirement passes somewhere, just never
## together.
## https://github.com/snackpackgames/cosmicparade/issues/62

var placeable: bool
var unsatisfiable: Array[PlacementCriterion]


func _init(is_placeable: bool, unmet: Array[PlacementCriterion] = []) -> void:
	placeable = is_placeable
	unsatisfiable = unmet
