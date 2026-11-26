extends GutTest
## What a piece projects is asked of the piece, never branched on by the board.


func _piece(domain: Domain.Kind, radius: int) -> Furniture:
	var piece := Furniture.new()
	piece.piece_name = "test piece"
	var projection := DomainProjection.new()
	projection.domain = domain
	projection.reach = radius
	piece.zone_source = projection
	piece.shape = Footprint.Shape.SINGLE
	return piece


func test_a_bare_board_piece_projects_nothing() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/77 — the Altar projects no
	# domain, no radius, and nothing for #37's tally. Null, not an empty zone.
	var piece := BoardPiece.new()
	assert_null(piece.zone_source)
	assert_false(piece.reads_influence())


func test_a_piece_reads_influence_when_it_carries_a_reading() -> void:
	var piece := BoardPiece.new()
	piece.reading = InfluenceReading.new()
	assert_true(piece.reads_influence())


func test_furniture_projects_its_authored_domain_at_its_authored_radius() -> void:
	var piece := _piece(Domain.Kind.FLAME, 2)
	var zone := piece.zone_source.zone_over([Vector2i.ZERO] as Array[Vector2i])
	assert_eq(zone.domain, Domain.Kind.FLAME)
	assert_eq(zone.hex_count(), 19)


func test_furniture_is_a_board_piece() -> void:
	assert_true(_piece(Domain.Kind.FOREST, 1) is BoardPiece)
