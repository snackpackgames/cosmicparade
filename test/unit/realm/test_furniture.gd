extends GutTest
## The authored furniture resource and the placeholder pieces in data/realm/furniture.


func test_every_authored_piece_is_loadable_and_has_a_name_and_a_shape() -> void:
	for file: String in DirAccess.get_files_at("res://data/realm/furniture"):
		var piece: Furniture = load("res://data/realm/furniture/%s" % file.trim_suffix(".remap"))
		assert_false(piece.piece_name.is_empty(), file)
		assert_true(piece.zone_radius >= 0, file)
		assert_true(Footprint.offsets_for(piece.shape).has(piece.anchor), "%s anchor" % file)


func test_zone_radius_defaults_to_one() -> void:
	# https://github.com/snackpackgames/cosmicparade/issues/52 — radius 1 is the
	# baseline, authored per piece.
	assert_eq(Furniture.new().zone_radius, 1)
