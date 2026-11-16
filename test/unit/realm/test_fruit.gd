extends GutTest
## The authored fruit. A placeholder in the way the authored furniture is: growing it is M2/M4,
## and all the map moved into scope is that an offering carries exactly one domain.
## https://github.com/snackpackgames/cosmicparade/issues/75


func test_the_authored_fruits_carry_one_domain_each() -> void:
	var plum: Fruit = load("res://data/realm/fruit/moss_plum.tres")
	var fig: Fruit = load("res://data/realm/fruit/ember_fig.tres")
	assert_eq(plum.domain, Domain.Kind.FOREST)
	assert_eq(fig.domain, Domain.Kind.FLAME)
	assert_true(plum is GameData)
