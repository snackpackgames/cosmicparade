extends GutTest
## One piece on the board: its hexes, its orientation, and the single zone it projects.


func _piece(shape: Footprint.Shape, domain: Domain.Kind, radius: int) -> Furniture:
	var piece := Furniture.new()
	piece.shape = shape
	piece.domain = domain
	piece.zone_radius = radius
	return piece


func test_a_placement_projects_one_zone_from_all_its_hexes() -> void:
	var hexes := Footprint.occupied(
		Footprint.Shape.STRAIGHT, 0, Vector2i.ZERO, Vector2i.ZERO
	)
	var placement := FurniturePlacement.new(
		_piece(Footprint.Shape.STRAIGHT, Domain.Kind.FOREST, 1), 0, hexes
	)
	assert_eq(placement.zone().hex_count(), 13)
	assert_eq(placement.zone().domain, Domain.Kind.FOREST)


func test_a_placement_remembers_its_orientation() -> void:
	var placement := FurniturePlacement.new(
		_piece(Footprint.Shape.SINGLE, Domain.Kind.GALE, 1), 4, [Vector2i.ZERO] as Array[Vector2i]
	)
	assert_eq(placement.orientation, 4)
