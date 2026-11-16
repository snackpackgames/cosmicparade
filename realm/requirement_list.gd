class_name RequirementList
extends Control
## PLACEHOLDER LAYOUT. The carried piece's own requirements, one line each, with the lines that
## failed on the current target flagged. Where this is drawn (panel, tooltip, text on the ghost)
## is deferred, which is why it is one Control with a small interface and a VBoxContainer of Labels
## inside. Marks are matched by identity and are never paired with board hexes.
## https://github.com/snackpackgames/cosmicparade/issues/62

const FAILING_COLOR := Color(1.0, 0.4, 0.4)
const FAILING_PREFIX := "! "

var _criteria: Array[PlacementCriterion] = []
var _failing: Array[PlacementCriterion] = []
var _box: VBoxContainer


func _ready() -> void:
	_ensure_box()


func show_requirements(criteria: Array[PlacementCriterion]) -> void:
	_criteria = criteria.duplicate()
	_failing = []
	_rebuild()


func mark_failing(criteria: Array[PlacementCriterion]) -> void:
	_failing = criteria.duplicate()
	_rebuild()


func hide_requirements() -> void:
	_criteria = []
	_failing = []
	_rebuild()


func lines() -> Array[String]:
	var result: Array[String] = []
	for criterion in _criteria:
		result.append(criterion.describe())
	return result


func failing_lines() -> Array[String]:
	var result: Array[String] = []
	for criterion in _criteria:
		if criterion in _failing:
			result.append(criterion.describe())
	return result


func _ensure_box() -> void:
	if _box != null:
		return
	_box = VBoxContainer.new()
	add_child(_box)


func _rebuild() -> void:
	_ensure_box()
	for child in _box.get_children():
		_box.remove_child(child)
		child.queue_free()
	for criterion in _criteria:
		var label := Label.new()
		var failing := criterion in _failing
		label.text = (FAILING_PREFIX if failing else "") + criterion.describe()
		if failing:
			label.add_theme_color_override("font_color", FAILING_COLOR)
		_box.add_child(label)
