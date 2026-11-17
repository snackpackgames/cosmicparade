extends GutTest


func test_a_new_balance_is_empty() -> void:
	assert_eq(AdherentBalance.new().adherents, 0)


func test_granting_accumulates() -> void:
	var balance := AdherentBalance.new()
	balance.grant(10)
	balance.grant(10)
	assert_eq(balance.adherents, 20)


func test_spending_what_is_not_there_is_refused_and_changes_nothing() -> void:
	var balance := AdherentBalance.new()
	balance.grant(10)
	assert_false(balance.spend(20))
	assert_eq(balance.adherents, 10)


func test_spending_what_is_there_succeeds_exactly() -> void:
	var balance := AdherentBalance.new()
	balance.grant(10)
	assert_true(balance.spend(10))
	assert_eq(balance.adherents, 0)
