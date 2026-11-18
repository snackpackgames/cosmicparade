class_name DebugReadout
extends CanvasLayer
## DEBUG ONLY. The three numbers this realm keeps — what the Altar reads, what the player can
## spend, and what the next Swell costs and grants — as plain text in a debug build. One rule for
## all three: nothing here is player-facing presentation, because that is `area:ui` work with no
## map behind it, and nothing in M1 spends the Altar's reading. PLACEHOLDER LAYOUT: a single
## Label in a corner. `text()` returns what is displayed, so a test reads the numbers without
## scraping the Label.
## https://github.com/snackpackgames/cosmicparade/issues/85

## The reading's range, stated so a readout of nothing is not read as a missing Altar.
const READING_RANGE := "0-4"
## Past the sixth Swell the action is unavailable rather than expensive, and a readout showing no
## price would be indistinguishable from a bug.
## https://github.com/snackpackgames/cosmicparade/issues/80
const NO_FURTHER_SWELL := "Swell: there is no further Swell"
const NOTHING_READ := "  nothing"
const MARGIN := 16.0
const WIDTH := 360.0
const HEIGHT := 200.0

var _lines: Array[String] = []
var _label: Label


func _ready() -> void:
	_ensure_label()


## Recomposes every line from values it is handed and keeps none of them: the reading is derived
## on demand and never stored, and the balance belongs to the realm.
## https://github.com/snackpackgames/cosmicparade/issues/79
func refresh(reading: AltarReading, balance: AdherentBalance, swell: Swell) -> void:
	_lines = _compose(reading, balance, swell)
	_ensure_label()
	_label.text = text()


## What is currently displayed, one line per fact.
func text() -> String:
	return "\n".join(_lines)


func _compose(reading: AltarReading, balance: AdherentBalance, swell: Swell) -> Array[String]:
	var lines: Array[String] = ["Altar reading (%s)" % READING_RANGE]
	lines.append_array(_reading_lines(reading))
	lines.append("Adherents %d" % balance.adherents)
	lines.append(_swell_line(swell))
	return lines


# One line per domain the Altar actually reads. A domain at zero is omitted rather than shown as
# 0, the same way a piece that projects nothing is absent from the tally instead of being a zero
# entry in it. Walking the enum rather than `domains_present()` keeps the order stable.
# https://github.com/snackpackgames/cosmicparade/issues/75
func _reading_lines(reading: AltarReading) -> Array[String]:
	var lines: Array[String] = []
	for domain: Domain.Kind in Domain.Kind.values():
		var count := reading.count_for(domain)
		if count > 0:
			lines.append("  %s %d" % [_domain_name(domain), count])
	if lines.is_empty():
		lines.append(NOTHING_READ)
	return lines


func _swell_line(swell: Swell) -> String:
	var tier := swell.next_tier()
	if tier == null:
		return NO_FURTHER_SWELL
	return "Swell: %s, %d adherents for %s" % [tier.tier_name, tier.cost, _grant_of(tier)]


func _grant_of(tier: SwellTier) -> String:
	var grant := "a ring" if tier.board_effect == SwellTier.Effect.RING else "a wing"
	if tier.shrine_capacity_delta > 0:
		grant += " and +%d shrine capacity" % tier.shrine_capacity_delta
	return grant


func _domain_name(domain: Domain.Kind) -> String:
	return (Domain.Kind.find_key(domain) as String).capitalize()


func _ensure_label() -> void:
	if _label != null:
		return
	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_label.offset_left = -MARGIN - WIDTH
	_label.offset_top = MARGIN
	_label.offset_right = -MARGIN
	_label.offset_bottom = MARGIN + HEIGHT
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
