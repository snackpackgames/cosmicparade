extends GutTest
## A region: contiguous hexes whose influence effects agree. Interior and boundary fall out of
## adjacency, with nothing extra stored.


func _region(hexes: Array[Vector2i]) -> MeldRegion:
	return MeldRegion.new([] as Array[InfluenceEffect], hexes)


func test_a_region_knows_its_size_and_its_members() -> void:
	var region := _region([Vector2i.ZERO, Vector2i(1, 0)])
	assert_eq(region.size(), 2)
	assert_true(region.contains(Vector2i(1, 0)))
	assert_false(region.contains(Vector2i(5, 5)))


# A disc of radius 1 is seven hexes: the centre has all six neighbours inside, the ring does not.
func test_the_centre_of_a_radius_one_disc_is_its_only_interior_hex() -> void:
	var region := _region(HexCoordinates.disc(Vector2i.ZERO, 1))
	assert_eq(region.interior(), [Vector2i.ZERO] as Array[Vector2i])
	assert_eq(region.boundary().size(), 6)


func test_a_single_hex_is_all_boundary() -> void:
	var region := _region([Vector2i.ZERO])
	assert_true(region.interior().is_empty())
	assert_eq(region.boundary(), [Vector2i.ZERO] as Array[Vector2i])
