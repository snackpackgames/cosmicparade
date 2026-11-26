extends GutTest
## An authored projection: fixed domain, fixed reach, shared by every placeable.


func test_it_projects_its_domain_at_its_reach() -> void:
	var projection := DomainProjection.new()
	projection.domain = Domain.Kind.GALE
	projection.reach = 2
	var zone := projection.zone_over([Vector2i.ZERO] as Array[Vector2i])
	assert_eq(zone.domain, Domain.Kind.GALE)
	assert_eq(zone.hex_count(), 19)


func test_it_is_shared_rather_than_copied() -> void:
	var projection := DomainProjection.new()
	assert_eq(projection.for_placement(), projection)


func test_it_holds_no_offering() -> void:
	assert_false(DomainProjection.new().can_hold_offering())
