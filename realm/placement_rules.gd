class_name PlacementRules
extends RefCounted
## The single call that judges a target: siting first, then every criterion against every
## occupied hex. A pure function of a candidate placement and the committed board.
## https://github.com/snackpackgames/cosmicparade/issues/55


static func verdict(
	piece: Furniture,
	orientation: int,
	target: Vector2i,
	grab_offset: Vector2i,
	state: RealmState
) -> PlacementVerdict:
	var occupied := Footprint.occupied(piece.shape, orientation, target, grab_offset)

	# Siting. Occupied hexes are board hexes by definition, and footprints never overlap.
	# https://github.com/snackpackgames/cosmicparade/issues/59
	var unsited: Array[Vector2i] = []
	for hex in occupied:
		if not state.geometry.has_hex(hex) or state.occupant_at(hex) != null:
			unsited.append(hex)
	if not unsited.is_empty():
		return PlacementVerdict.new(false, unsited)

	# The board as it will be with the piece on it.
	# https://github.com/snackpackgames/cosmicparade/issues/41
	var zones := state.zones()
	zones.append(InfluenceZone.project(piece.domain, occupied, piece.zone_radius))
	var context := PlacementContext.new(state, occupied, zones)

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


static func zone_for(
	piece: Furniture, orientation: int, target: Vector2i, grab_offset: Vector2i
) -> InfluenceZone:
	return InfluenceZone.project(
		piece.domain,
		Footprint.occupied(piece.shape, orientation, target, grab_offset),
		piece.zone_radius
	)
