extends GutTest
## The authored furniture resource and the placeholder pieces in data/realm/furniture.


func test_every_authored_piece_is_loadable_and_has_a_name_and_a_shape() -> void:
	for file: String in DirAccess.get_files_at("res://data/realm/furniture"):
		var piece: Furniture = load("res://data/realm/furniture/%s" % file.trim_suffix(".remap"))
		assert_false(piece.piece_name.is_empty(), file)
		assert_true((piece.zone_source as DomainProjection).reach >= 0, file)
		assert_true(Footprint.offsets_for(piece.shape).has(piece.anchor), "%s anchor" % file)


func test_reach_defaults_to_one() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/52 — radius 1 is the
	# baseline, authored per piece.
	assert_eq(DomainProjection.new().reach, 1)


func test_no_authored_piece_requires_one_zone_of_its_own_domain() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/55 — "domain X >= 1"
	# where X is the piece's own domain is always true, because the piece's own
	# zone covers all of its own hexes. Harmless, but a no-op.
	for file: String in DirAccess.get_files_at("res://data/realm/furniture"):
		var piece: Furniture = load("res://data/realm/furniture/%s" % file.trim_suffix(".remap"))
		for criterion: PlacementCriterion in piece.criteria:
			if criterion is DomainInfluenceCriterion:
				var influence := criterion as DomainInfluenceCriterion
				assert_false(
					influence.domain == (piece.zone_source as DomainProjection).domain and influence.minimum <= 1,
					"%s authors a no-op criterion" % file
				)
