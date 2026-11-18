class_name AdherentBalance
extends RefCounted
## The adherents the realm can spend. A plain object the realm constructs and injects: not a
## Resource (Godot caches those by path, so a mutated one is shared), not a field on RealmState
## (adherents are earned in the parade and spent in the realm) and not an autoload (nothing yet
## needs it to outlive a scene change). No signal, because nothing listens.
## https://github.com/snackpackgames/cosmicparade/issues/76

var adherents: int = 0


func can_afford(cost: int) -> bool:
	return adherents >= cost


## Debits `cost` and returns true, or returns false and changes nothing.
func spend(cost: int) -> bool:
	if not can_afford(cost):
		return false
	adherents -= cost
	return true


func grant(amount: int) -> void:
	adherents += amount
