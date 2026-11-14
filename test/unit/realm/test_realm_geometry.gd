extends GutTest
## The board: a core radius plus an ordered set of placed wings.
## https://github.com/snackpackgames/cosmicparade/issues/53

const DISC_PATH := "res://data/realm/wing_shape/disc.tres"


func test_a_fresh_realm_is_a_radius_three_hexagon_of_thirty_seven_spaces() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/50
	var geometry := RealmGeometry.new()
	assert_eq(geometry.core_radius, 3)
	assert_eq(geometry.hexes().size(), 37)
	assert_true(geometry.has_hex(Vector2i.ZERO))
	assert_false(geometry.has_hex(Vector2i(4, 0)))


func test_the_first_two_swells_add_rings_and_the_third_adds_none() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/53
	var geometry := RealmGeometry.new()
	assert_eq(geometry.swell().size(), 24)
	assert_eq(geometry.hexes().size(), 61)
	assert_eq(geometry.swell().size(), 30)
	assert_eq(geometry.hexes().size(), 91)
	assert_eq(geometry.core_radius, RealmGeometry.CORE_MAX_RADIUS)
	assert_eq(geometry.swell(), [] as Array[Vector2i], "the core never grows again")
	assert_eq(geometry.hexes().size(), 91)


func test_the_origin_never_moves() -> void:
	var geometry := RealmGeometry.new()
	geometry.swell()
	assert_true(geometry.has_hex(Vector2i.ZERO))
	assert_true(geometry.has_hex(Vector2i(3, 0)), "ring 3 is still ring 3")


func test_a_wing_must_share_an_edge_with_the_board() -> void:
	var geometry := RealmGeometry.new()
	var disc: WingShape = load(DISC_PATH)
	assert_false(geometry.can_attach(disc, 0, Vector2i(20, 0)), "nowhere near the board")
	assert_true(geometry.can_attach(disc, 0, Vector2i(5, -1)), "edge-adjacent to ring 3")


func test_a_wing_may_not_overlap_the_board() -> void:
	var geometry := RealmGeometry.new()
	var disc: WingShape = load(DISC_PATH)
	assert_false(geometry.can_attach(disc, 0, Vector2i.ZERO))


func test_attaching_a_wing_adds_exactly_its_hexes() -> void:
	var geometry := RealmGeometry.new()
	var disc: WingShape = load(DISC_PATH)
	assert_eq(geometry.attach(disc, 0, Vector2i(5, -1)).size(), 7)
	assert_eq(geometry.hexes().size(), 44)
	assert_true(geometry.has_hex(Vector2i(5, -1)))


func test_wings_may_chain_off_another_wing() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/53
	var geometry := RealmGeometry.new()
	var disc: WingShape = load(DISC_PATH)
	geometry.attach(disc, 0, Vector2i(5, -1))
	assert_true(geometry.can_attach(disc, 0, Vector2i(8, -2)))


func test_no_rule_knows_a_hex_is_on_a_wing() -> void:
	# wing_index_at exists for lifting a wing and for nothing else.
	var geometry := RealmGeometry.new()
	geometry.attach(load(DISC_PATH), 0, Vector2i(5, -1))
	assert_eq(geometry.wing_index_at(Vector2i.ZERO), -1)
	assert_eq(geometry.wing_index_at(Vector2i(5, -1)), 0)


func test_an_edge_hex_is_a_board_hex_with_an_absent_neighbour() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/55
	var geometry := RealmGeometry.new()
	assert_true(geometry.is_edge_hex(Vector2i(3, 0)))
	assert_false(geometry.is_edge_hex(Vector2i.ZERO))
	assert_false(geometry.is_edge_hex(Vector2i(9, 9)), "off the board is not an edge hex")


func test_attaching_a_wing_rewrites_the_boards_edge() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/53 — the edge is
	# irregular and mutable. #55 accepts the drift because criteria are a gate
	# checked once and never re-checked.
	var geometry := RealmGeometry.new()
	var disc: WingShape = load(DISC_PATH)
	assert_false(geometry.has_hex(Vector2i(4, -1)), "void before the Swell")
	geometry.attach(disc, 0, Vector2i(5, -1))
	assert_true(geometry.is_edge_hex(Vector2i(4, -1)), "board now, and on the new rim")
	assert_true(geometry.is_edge_hex(Vector2i(3, -1)), "a core hex keeps an absent neighbour")


func test_lifting_a_wing_removes_exactly_its_hexes() -> void:
	var geometry := RealmGeometry.new()
	geometry.attach(load(DISC_PATH), 0, Vector2i(5, -1))
	assert_eq(geometry.lift_wing(0).size(), 7)
	assert_eq(geometry.hexes().size(), 37)
	assert_eq(geometry.wings.size(), 0)


# Review Focus 3: wings chain, so a lift can orphan one.
func test_lifting_a_wing_another_wing_hangs_off_is_refused() -> void:
	var geometry := RealmGeometry.new()
	var disc: WingShape = load(DISC_PATH)
	geometry.attach(disc, 0, Vector2i(5, -1))
	geometry.attach(disc, 0, Vector2i(8, -2))
	assert_false(geometry.can_lift_wing(0), "it carries the second wing's only edge")
	assert_eq(geometry.lift_wing(0), [] as Array[Vector2i], "and the lift does nothing")
	assert_eq(geometry.hexes().size(), 51)
	assert_true(geometry.can_lift_wing(1), "the outer wing comes off freely")
