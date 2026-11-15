extends GutTest
## One wing on the board: a shape, a rotation and an anchor.


func test_a_placed_wing_is_its_shape_rotated_and_translated() -> void:
	var wing := PlacedWing.new(load("res://data/realm/wing_shape/disc.tres"), 0, Vector2i(5, -2))
	assert_eq(wing.hexes().size(), 7)
	assert_true(wing.hexes().has(Vector2i(5, -2)))


func test_rotation_steps_wrap() -> void:
	var shape: WingShape = load("res://data/realm/wing_shape/trapezoid.tres")
	assert_eq(
		PlacedWing.new(shape, 6, Vector2i.ZERO).hexes(),
		PlacedWing.new(shape, 0, Vector2i.ZERO).hexes()
	)
