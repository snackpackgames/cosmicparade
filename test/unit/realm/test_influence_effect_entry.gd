extends GutTest
## One row of the table: a set of domains and the effect they produce.


func _entry(domains: Array[int]) -> InfluenceEffectEntry:
	var entry := InfluenceEffectEntry.new()
	entry.domains = domains
	entry.effect = InfluenceEffect.new()
	return entry


func test_an_entry_claims_a_hex_whose_domains_contain_all_of_its_own() -> void:
	var entry := _entry([Domain.Kind.FOREST, Domain.Kind.FLAME])
	var available := {Domain.Kind.FOREST: true, Domain.Kind.FLAME: true, Domain.Kind.STONE: true}
	assert_true(entry.claims_within(available))


func test_an_entry_missing_one_domain_claims_nothing() -> void:
	var entry := _entry([Domain.Kind.FOREST, Domain.Kind.FLAME])
	assert_false(entry.claims_within({Domain.Kind.FOREST: true}))


func test_a_one_domain_entry_claims_that_domain() -> void:
	assert_true(_entry([Domain.Kind.STONE]).claims_within({Domain.Kind.STONE: true}))


# https://github.com/snackpackgames/cosmicparade/issues/107 — no empty entries. An entry claiming
# no domains is a subset of everything, so without this it would match every hex forever.
func test_an_entry_claiming_no_domains_never_claims_anything() -> void:
	assert_false(_entry([]).claims_within({Domain.Kind.STONE: true}))
	assert_false(_entry([]).claims_within({}))
