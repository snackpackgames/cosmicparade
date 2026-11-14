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


func test_the_six_directions_are_unit_steps() -> void:
	assert_eq(HexCoordinates.DIRECTIONS.size(), 6)
	for direction: Vector2i in HexCoordinates.DIRECTIONS:
		assert_eq(HexCoordinates.distance(Vector2i.ZERO, direction), 1)


func test_a_hex_has_six_neighbors_all_one_away() -> void:
	var neighbors := HexCoordinates.neighbors(Vector2i(2, -1))
	assert_eq(neighbors.size(), 6)
	for neighbor: Vector2i in neighbors:
		assert_eq(HexCoordinates.distance(Vector2i(2, -1), neighbor), 1)


func test_six_rotation_steps_return_a_hex_to_itself() -> void:
	assert_eq(HexCoordinates.rotate(Vector2i(2, -1), 6), Vector2i(2, -1))


func test_one_rotation_step_walks_the_directions() -> void:
	# Rotating direction i by one step gives direction i + 1.
	for i in 6:
		assert_eq(
			HexCoordinates.rotate(HexCoordinates.DIRECTIONS[i], 1),
			HexCoordinates.DIRECTIONS[(i + 1) % 6]
		)


func test_rotation_preserves_distance_from_the_origin() -> void:
	assert_eq(HexCoordinates.distance(Vector2i.ZERO, HexCoordinates.rotate(Vector2i(3, -1), 2)), 3)


func test_negative_rotation_steps_turn_the_other_way() -> void:
	assert_eq(HexCoordinates.rotate(Vector2i(1, 0), -1), HexCoordinates.DIRECTIONS[5])


func test_a_disc_holds_three_n_squared_plus_three_n_plus_one_hexes() -> void:
	assert_eq(HexCoordinates.disc(Vector2i.ZERO, 0).size(), 1)
	assert_eq(HexCoordinates.disc(Vector2i.ZERO, 1).size(), 7)
	assert_eq(HexCoordinates.disc(Vector2i.ZERO, 3).size(), 37)
	assert_eq(HexCoordinates.disc(Vector2i.ZERO, 5).size(), 91)


func test_a_disc_is_centred_where_it_was_asked_to_be() -> void:
	var disc := HexCoordinates.disc(Vector2i(4, -2), 2)
	assert_true(disc.has(Vector2i(4, -2)))
	for hex: Vector2i in disc:
		assert_lte(HexCoordinates.distance(Vector2i(4, -2), hex), 2)


func test_a_ring_holds_six_n_hexes_and_a_radius_zero_ring_is_its_centre() -> void:
	assert_eq(HexCoordinates.ring(Vector2i.ZERO, 0), [Vector2i.ZERO] as Array[Vector2i])
	assert_eq(HexCoordinates.ring(Vector2i.ZERO, 4).size(), 24)
	assert_eq(HexCoordinates.ring(Vector2i.ZERO, 5).size(), 30)


func test_a_ring_is_exactly_the_hexes_that_far_out() -> void:
	for hex: Vector2i in HexCoordinates.ring(Vector2i.ZERO, 3):
		assert_eq(HexCoordinates.distance(Vector2i.ZERO, hex), 3)
