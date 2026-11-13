extends GutTest
## The six domains, and nothing per-domain beyond their names.

func test_there_are_exactly_six_domains() -> void:
	assert_eq(Domain.Kind.size(), 6)


func test_every_domain_in_the_design_document_is_present() -> void:
	for name: String in ["FOREST", "GRASSLAND", "WETLAND", "STONE", "FLAME", "GALE"]:
		assert_true(Domain.Kind.has(name), "Domain.Kind should have %s" % name)
