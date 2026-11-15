class_name DomainInfluenceCriterion
extends PlacementCriterion
## At least `minimum` zones of one domain must cover every hex of the footprint. The count
## includes the placing piece's own zone, so `Forest >= 2` means "a Forest neighbour" and also
## "Forest ground raised here".
## https://github.com/snackpackgames/cosmicparade/issues/55

@export var domain: Domain.Kind = Domain.Kind.FOREST
@export var minimum: int = 1


func failing_hexes(context: PlacementContext) -> Array[Vector2i]:
	var failing: Array[Vector2i] = []
	for hex in context.occupied:
		if context.zone_count(domain, hex) < minimum:
			failing.append(hex)
	return failing


func describe() -> String:
	return "%s >= %d" % [(Domain.Kind.find_key(domain) as String).capitalize(), minimum]
