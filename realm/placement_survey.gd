class_name PlacementSurvey
extends RefCounted
## What one sweep of the board says about a piece: whether any legal target exists at all, and
## which of its requirements nothing on the realm satisfies. An empty `unsatisfiable` beside
## `placeable == false` is a real state under AND: each requirement passes somewhere, never all
## at once.
## https://github.com/snackpackgames/cosmicparade/issues/62

var placeable: bool
var unsatisfiable: Array[PlacementCriterion]


func _init(is_placeable: bool, criteria: Array[PlacementCriterion] = []) -> void:
	placeable = is_placeable
	unsatisfiable = criteria
