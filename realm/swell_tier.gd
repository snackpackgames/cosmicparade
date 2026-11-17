class_name SwellTier
extends GameData
## One row of the Swell ladder: what it grows, what capacity it grants and what it costs.
## Authored so prices can be tuned without a rebuild.
## https://github.com/snackpackgames/cosmicparade/issues/80
## https://github.com/snackpackgames/cosmicparade/issues/81

enum Effect { RING, WING }

@export var tier_name: String = ""
@export var board_effect: Effect = Effect.RING
@export var shrine_capacity_delta: int = 0
@export var cost: int = 0
