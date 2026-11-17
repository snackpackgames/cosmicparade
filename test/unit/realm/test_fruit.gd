extends GutTest
## The placeholder fruit: a name and exactly one domain.


func test_the_authored_fruits_carry_one_domain_each() -> void:
	var plum: Fruit = load("res://data/realm/fruit/moss_plum.tres")
	var fig: Fruit = load("res://data/realm/fruit/ember_fig.tres")
	assert_eq(plum.domain, Domain.Kind.FOREST)
	assert_eq(fig.domain, Domain.Kind.FLAME)
	assert_true(plum is GameData)
