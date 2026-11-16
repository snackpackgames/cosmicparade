class_name RequirementList
extends Control
## PLACEHOLDER LAYOUT. The carried piece's own requirements, one line each, with the failing
## ones flagged. Where this is drawn (panel, tooltip, text on the ghost) is deferred, which is
## why it is one Control with a small interface. Unpaired with the board's marks on purpose.
## https://github.com/snackpackgames/cosmicparade/issues/62

const FAILING_COLOR := Color(1.0, 0.4, 0.4)

var _criteria: Array[PlacementCriterion] = []
var _failing: Array[PlacementCriterion] = []
var _box := VBoxContainer.new()


func _init() -> void:
	_box.name = "Lines"
	add_child(_box)


func show_requirements(criteria: Array[PlacementCriterion]) -> void:
	_criteria = criteria.duplicate()
	_failing.clear()
	_rebuild()


func mark_failing(criteria: Array[PlacementCriterion]) -> void:
	_failing.clear()
	for criterion in criteria:
		if _criteria.has(criterion):
			_failing.append(criterion)
	_rebuild()


func hide_requirements() -> void:
	_criteria.clear()
	_failing.clear()
	_rebuild()


func lines() -> Array[String]:
	var result: Array[String] = []
	for criterion in _criteria:
		result.append(criterion.describe())
	return result


func failing_lines() -> Array[String]:
	var result: Array[String] = []
	for criterion in _criteria:
		if _failing.has(criterion):
			result.append(criterion.describe())
	return result


func _rebuild() -> void:
	for child in _box.get_children():
		_box.remove_child(child)
		child.queue_free()
	for criterion in _criteria:
		var label := Label.new()
		label.text = criterion.describe()
		if _failing.has(criterion):
			label.add_theme_color_override("font_color", FAILING_COLOR)
		_box.add_child(label)
