extends GutTest
## Flat-top axial hex geometry.

func test_distance_is_zero_to_itself() -> void:
	assert_eq(HexCoordinates.distance(Vector2i(2, -3), Vector2i(2, -3)), 0)


func test_distance_counts_steps_between_neighbours() -> void:
	assert_eq(HexCoordinates.distance(Vector2i.ZERO, Vector2i(1, 0)), 1)
	assert_eq(HexCoordinates.distance(Vector2i.ZERO, Vector2i(1, -1)), 1)
	assert_eq(HexCoordinates.distance(Vector2i.ZERO, Vector2i(2, -1)), 2)
	assert_eq(HexCoordinates.distance(Vector2i(-2, 1), Vector2i(2, -1)), 4)


func test_origin_sits_at_the_world_origin() -> void:
	assert_eq(HexCoordinates.center_of(Vector2i.ZERO), Vector3.ZERO)


func test_centres_lie_flat_on_the_xz_plane() -> void:
	assert_eq(HexCoordinates.center_of(Vector2i(3, -2)).y, 0.0)


# Review Focus 1: an odd q must be halved as a float. Integer division would
# put this hex a full half-row out of place, and every other column with it.
func test_odd_q_offsets_the_row_by_half_a_step() -> void:
	var center := HexCoordinates.center_of(Vector2i(1, 0))
	assert_almost_eq(center.x, 1.5, 0.0001)
	assert_almost_eq(center.z, sqrt(3.0) * 0.5, 0.0001)


func test_negative_coordinates_mirror_positive_ones() -> void:
	var positive := HexCoordinates.center_of(Vector2i(3, -1))
	var negative := HexCoordinates.center_of(Vector2i(-3, 1))
	assert_almost_eq(negative.x, -positive.x, 0.0001)
	assert_almost_eq(negative.z, -positive.z, 0.0001)


func test_there_are_six_corner_offsets_at_the_circumradius() -> void:
	var offsets := HexCoordinates.corner_offsets()
	assert_eq(offsets.size(), 6)
	for offset: Vector3 in offsets:
		assert_almost_eq(Vector2(offset.x, offset.z).length(), HexCoordinates.CIRCUMRADIUS, 0.0001)
		assert_eq(offset.y, 0.0)
