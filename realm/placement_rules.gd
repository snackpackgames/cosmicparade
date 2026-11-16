class_name PlacementRules
extends RefCounted
## The single call that judges a target: siting first, then every criterion against every
## occupied hex. A pure function of a candidate placement and the committed board. Judges any
## board piece — what a piece projects is asked of the piece, never branched on here.
## https://github.com/snackpackgames/cosmicparade/issues/55
## https://github.com/snackpackgames/cosmicparade/issues/74


static func verdict(
	piece: BoardPiece,
	orientation: int,
	target: Vector2i,
	grab_offset: Vector2i,
	state: RealmState
) -> PlacementVerdict:
	var occupied := Footprint.occupied(piece.shape, orientation, target, grab_offset)
	var unsited := _unsited(occupied, state)
	if not unsited.is_empty():
		return PlacementVerdict.new(false, unsited)
	var context := _context_for(piece, occupied, state)

	var failing_hexes: Dictionary = {}
	var failing_criteria: Array[PlacementCriterion] = []
	for criterion in piece.criteria:
		var hexes := criterion.failing_hexes(context)
		if hexes.is_empty():
			continue
		failing_criteria.append(criterion)
		for hex in hexes:
			failing_hexes[hex] = true
	var marked: Array[Vector2i] = []
	marked.assign(failing_hexes.keys())
	return PlacementVerdict.new(failing_criteria.is_empty(), marked, failing_criteria)


## The zone the piece would project from the target, or null for a piece that projects nothing.
## https://github.com/snackpackgames/cosmicparade/issues/77
static func zone_for(
	piece: BoardPiece, orientation: int, target: Vector2i, grab_offset: Vector2i
) -> InfluenceZone:
	return piece.zone_for(Footprint.occupied(piece.shape, orientation, target, grab_offset))


## One sweep over every board hex and all six orientations, run on lift. Records which criteria
## pass somewhere and whether some single placement passes them all.
static func survey(
	piece: BoardPiece, grab_offset: Vector2i, state: RealmState
) -> PlacementSurvey:
	var passed_somewhere: Array[bool] = []
	passed_somewhere.resize(piece.criteria.size())
	passed_somewhere.fill(false)
	var placeable := false
	for target in state.geometry.hexes():
		for orientation in 6:
			var occupied := Footprint.occupied(piece.shape, orientation, target, grab_offset)
			if not _unsited(occupied, state).is_empty():
				continue
			var context := _context_for(piece, occupied, state)
			var passes_all := true
			for i in piece.criteria.size():
				if piece.criteria[i].failing_hexes(context).is_empty():
					passed_somewhere[i] = true
				else:
					passes_all = false
			placeable = placeable or passes_all
	var unsatisfiable: Array[PlacementCriterion] = []
	for i in piece.criteria.size():
		if not passed_somewhere[i]:
			unsatisfiable.append(piece.criteria[i])
	return PlacementSurvey.new(placeable, unsatisfiable)


# Siting. Occupied hexes are board hexes by definition, and footprints never overlap.
# https://github.com/snackpackgames/cosmicparade/issues/59
static func _unsited(occupied: Array[Vector2i], state: RealmState) -> Array[Vector2i]:
	var unsited: Array[Vector2i] = []
	for hex in occupied:
		if not state.geometry.has_hex(hex) or state.occupant_at(hex) != null:
			unsited.append(hex)
	return unsited


# The board as it will be with the piece on it, own influence included — and only its own
# influence if it has any. A piece that projects nothing adds no zone, or an empty shrine
# vessel would be judged against a zone it does not project.
# https://github.com/snackpackgames/cosmicparade/issues/41
# https://github.com/snackpackgames/cosmicparade/issues/75
static func _context_for(
	piece: BoardPiece, occupied: Array[Vector2i], state: RealmState
) -> PlacementContext:
	var zones := state.zones()
	var candidate := piece.zone_for(occupied)
	if candidate != null:
		zones.append(candidate)
	return PlacementContext.new(state, occupied, zones)
