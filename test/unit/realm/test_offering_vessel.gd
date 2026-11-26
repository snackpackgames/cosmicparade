extends GutTest
## The shrine's zone source: projects what it holds, and is copied per placeable.


func _fruit(domain: Domain.Kind) -> Fruit:
	var fruit := Fruit.new()
	fruit.fruit_name = "test fruit"
	fruit.domain = domain
	return fruit


func test_an_empty_vessel_projects_nothing() -> void:
	var vessel := OfferingVessel.new()
	assert_null(vessel.zone_over([Vector2i.ZERO] as Array[Vector2i]))


func test_a_fed_vessel_projects_its_offerings_domain_at_its_own_reach() -> void:
	var vessel := OfferingVessel.new()
	vessel.reach = 2
	vessel.accept_offering(_fruit(Domain.Kind.FLAME))
	var zone := vessel.zone_over([Vector2i.ZERO] as Array[Vector2i])
	assert_eq(zone.domain, Domain.Kind.FLAME, "the fruit supplies only the domain")
	assert_eq(zone.hex_count(), 19)
	assert_true(zone.covers(Vector2i(2, 0)), "the reach is the vessel's")


func test_it_holds_an_offering_only_once_fed() -> void:
	var vessel := OfferingVessel.new()
	assert_true(vessel.can_hold_offering(), "it is a vessel whether or not it is fed")
	assert_false(vessel.holds_offering())
	vessel.accept_offering(_fruit(Domain.Kind.FOREST))
	assert_true(vessel.holds_offering())
	vessel.empty_vessel()
	assert_false(vessel.holds_offering())


func test_two_placement_copies_of_one_authored_vessel_do_not_share_contents() -> void:
	var authored := OfferingVessel.new()
	authored.reach = 2
	var first: ZoneSource = authored.for_placement()
	var second: ZoneSource = authored.for_placement()
	assert_ne(first, second, "each placeable gets its own vessel")
	first.accept_offering(_fruit(Domain.Kind.FOREST))
	assert_false(second.holds_offering(), "feeding one must not feed the other")
	assert_false(authored.holds_offering(), "nor the authored resource")
	assert_eq(second.reach, 2, "the copy keeps its authored reach")
