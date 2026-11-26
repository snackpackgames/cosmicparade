@tool
class_name RealmBoard
extends Node3D
## The realm board: one hex space per coordinate it was given.
##
## `@tool` is here so the editor viewport is not empty. The board is generated from its radius
## rather than stored as a hex set (`adr/0015`), and a hex's height is derived from the influence
## zones on it rather than authored (`adr/0014`), so `realm.tscn` holds no hex nodes at all and
## there is nothing to frame a camera or a light against until the scene runs.
## The annotation stays on this node and off `Realm`, whose `_ready` places the Altar, configures
## the carry and connects six signals -- none of which belongs in the editor.
## https://github.com/snackpackgames/cosmicparade/issues/146

## Draws the board in the editor viewport. Editor-only in both directions: it does nothing at
## runtime, and the spaces it makes are never saved, because the scene must keep holding zero
## authored hexes or the preview could drift from what the runtime generates.
@export var preview_in_editor := true:
	set(value):
		preview_in_editor = value
		if is_node_ready():
			_refresh_preview()

## Which core radius to preview. Framing against the concentric ceiling matters as much as
## against the opening board, and `adr/0015` caps that at `CORE_MAX_RADIUS`.
@export_range(1, RealmGeometry.CORE_MAX_RADIUS)
var preview_radius: int = RealmGeometry.CORE_START_RADIUS:
	set(value):
		preview_radius = value
		if is_node_ready():
			_refresh_preview()

var zones: Array[InfluenceZone] = []

var _spaces: Dictionary = {}
var _material: ShaderMaterial


func _ready() -> void:
	if Engine.is_editor_hint():
		_refresh_preview()


func build(hexes: Array[Vector2i]) -> void:
	_material = BoardMaterial.create()
	for hex in hexes:
		_add_space(hex)


## Reconciles the spaces with a new extent: adds what arrived, frees what went away, and leaves
## every other space the same node, so growth costs work proportional to the change.
## https://github.com/snackpackgames/cosmicparade/issues/59
func set_hexes(hexes: Array[Vector2i]) -> void:
	var wanted: Dictionary = {}
	for hex in hexes:
		wanted[hex] = true
		if not _spaces.has(hex):
			_add_space(hex)
	for hex: Vector2i in _spaces.keys():
		if not wanted.has(hex):
			_spaces[hex].queue_free()
			_spaces.erase(hex)


func rebuild(changed_hexes: Array[Vector2i]) -> void:
	for hex in changed_hexes:
		var space: HexSpace = _spaces.get(hex)
		if space != null:
			space.set_depth(Elevation.depth_at(hex, zones))


func hex_space(hex: Vector2i) -> HexSpace:
	return _spaces.get(hex)


## Reconciles the preview with the exported settings, reusing the same `set_hexes` the Swell
## path uses so a radius change costs work proportional to the hexes that arrived or left
## (https://github.com/snackpackgames/cosmicparade/issues/59). An empty realm has no influence,
## so every previewed hex sits at depth 0 -- the board is honestly flat, not merely unfinished.
func _refresh_preview() -> void:
	if not Engine.is_editor_hint():
		return
	set_hexes(_preview_hexes())


## The extent the preview draws: the core at the previewed radius, or nothing at all when the
## preview is switched off. Split from `_refresh_preview` so what the editor will show is
## testable, leaving the `Engine.is_editor_hint()` guard as the only line a test cannot reach.
func _preview_hexes() -> Array[Vector2i]:
	if not preview_in_editor:
		return [] as Array[Vector2i]
	var geometry := RealmGeometry.new()
	geometry.core_radius = preview_radius
	return geometry.hexes()


func _add_space(hex: Vector2i) -> void:
	if _material == null:
		_material = BoardMaterial.create()
	var space := HexSpace.new()
	space.configure(hex, _material)
	add_child(space)
	_spaces[hex] = space
	space.set_depth(Elevation.depth_at(hex, zones))
