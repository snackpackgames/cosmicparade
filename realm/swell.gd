class_name Swell
extends RefCounted
## Swell as a purchase: the price of the next one, and the order of operations. Check
## affordability, perform the geometry, debit only if the board actually changed. No refunds.
## RealmGeometry knows nothing of cost and AdherentBalance nothing of Swell.
## https://github.com/snackpackgames/cosmicparade/issues/76

## Six rows, in order. There is no seventh: past the fourth wing the action is unavailable.
## https://github.com/snackpackgames/cosmicparade/issues/80
const TIER_PATHS: Array[String] = [
	"res://data/realm/swell_tier/01_first_ring.tres",
	"res://data/realm/swell_tier/02_second_ring.tres",
	"res://data/realm/swell_tier/03_first_wing.tres",
	"res://data/realm/swell_tier/04_second_wing.tres",
	"res://data/realm/swell_tier/05_third_wing.tres",
	"res://data/realm/swell_tier/06_fourth_wing.tres",
]

var tiers_taken: int = 0

var _state: RealmState
var _balance: AdherentBalance


func _init(state: RealmState, balance: AdherentBalance) -> void:
	_state = state
	_balance = balance


func is_available() -> bool:
	return tiers_taken < TIER_PATHS.size()


func next_tier() -> SwellTier:
	if not is_available():
		return null
	return load(TIER_PATHS[tiers_taken])


## The price of the next Swell, readable before any interaction starts. 0 when none remains.
func cost_for_next() -> int:
	var tier := next_tier()
	return 0 if tier == null else tier.cost


func can_afford() -> bool:
	return is_available() and _balance.can_afford(cost_for_next())


## Buys the next Swell if it is a ring. Returns the hexes that arrived, empty when nothing
## changed: unavailable, unaffordable, not a ring, or the geometry refused.
func take_ring() -> Array[Vector2i]:
	var tier := next_tier()
	if tier == null or tier.board_effect != SwellTier.Effect.RING or not can_afford():
		return [] as Array[Vector2i]
	var arrived := _state.geometry.swell()
	if arrived.is_empty():
		return arrived
	_balance.spend(tier.cost)
	_state.shrine_capacity += tier.shrine_capacity_delta
	tiers_taken += 1
	return arrived
