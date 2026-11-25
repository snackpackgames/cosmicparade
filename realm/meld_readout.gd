class_name MeldReadout
extends CanvasLayer
## DEBUG ONLY. The whole derivation of one hex's influence effects: what covers it and in what
## numbers, which authored entries fired, at what index and intensity, the depth beneath them,
## the resulting effects, and how many neighbouring hexes agree. It shows the **inputs and the
## match**, never the rendered result — the rendered result is the game rendering, not a debug
## view. PLACEHOLDER LAYOUT: a single Label in a corner. `text()` returns what is displayed.
## https://github.com/snackpackgames/cosmicparade/issues/110

## Stated rather than left blank, on `DebugReadout`'s own grounds: a readout of nothing is
## indistinguishable from a broken one.
const NOTHING_COVERS := "  nothing covers this hex"
const MARGIN := 16.0
const WIDTH := 420.0
const HEIGHT := 200.0
const LABEL_WIDTH := 15

var _lines: Array[String] = []
var _label: Label


func _ready() -> void:
	_ensure_label()


## Recomposes every line from the values it is handed and keeps none of them: the whole block is
## derived on demand, exactly as the resolution it reads is.
func refresh(hex: Vector2i, zones: Array[InfluenceZone], table: InfluenceEffectTable) -> void:
	_lines = _compose(hex, zones, table)
	_ensure_label()
	_label.text = text()


## What is currently displayed, one line per fact.
func text() -> String:
	return "\n".join(_lines)


func _compose(
	hex: Vector2i, zones: Array[InfluenceZone], table: InfluenceEffectTable
) -> Array[String]:
	var lines: Array[String] = ["Meld at (%d,%d)" % [hex.x, hex.y]]
	var resolution := Meld.resolve(hex, zones, table)
	if resolution.is_empty():
		lines.append(NOTHING_COVERS)
		return lines
	lines.append("  covering   %s" % _covering(resolution))
	for effect_match in resolution.matches:
		lines.append(_entry_line(effect_match))
	lines.append(
		(
			"  depth %d    from %s, %s"
			% [
				resolution.depth,
				_domain_name(resolution.depth_domain),
				"at ceiling" if resolution.at_ceiling else "not at ceiling",
			]
		)
	)
	var effect_names: Array[String] = []
	for effect in resolution.effects():
		effect_names.append(effect.effect_name)
	lines.append("  effects    %s" % ", ".join(effect_names))
	var region := Meld.region_at(hex, zones, table)
	lines.append("  region     %d hexes agree" % region.hexes.size())
	return lines


# Walks the enum rather than the dictionary so the order is stable whatever order the zones
# arrive in.
func _covering(resolution: MeldResolution) -> String:
	var parts: Array[String] = []
	for domain: Domain.Kind in Domain.Kind.values():
		if resolution.zone_counts.has(domain):
			parts.append("%s x%d" % [_domain_name(domain), resolution.zone_counts[domain]])
	return ", ".join(parts)


# The provenance is printed only where it can go wrong: a one-domain entry's intensity can only
# have come from its own domain.
func _entry_line(effect_match: EffectMatch) -> String:
	var names: Array[String] = []
	for domain in effect_match.domains:
		names.append(_domain_name(domain as Domain.Kind))
	var line := (
		"  entry %d    %sintensity %d"
		% [effect_match.entry_index, "+".join(names).rpad(LABEL_WIDTH), effect_match.intensity]
	)
	if effect_match.domains.size() > 1:
		line += ", from %s" % _domain_name(effect_match.intensity_domain)
	return line


func _domain_name(domain: Domain.Kind) -> String:
	return (Domain.Kind.find_key(domain) as String).capitalize()


func _ensure_label() -> void:
	if _label != null:
		return
	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_label.offset_left = -MARGIN - WIDTH
	_label.offset_top = -MARGIN - HEIGHT
	_label.offset_right = -MARGIN
	_label.offset_bottom = -MARGIN
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
