class_name InfluenceEffectTable
extends GameData
## Every influence effect the board can show, keyed by the domain influence that produces it.
## https://github.com/snackpackgames/cosmicparade/issues/107
## https://github.com/snackpackgames/cosmicparade/issues/113

## The realm's one authored table.
const BOARD_PATH := "res://data/realm/influence_effect_table/board.tres"

## Ordered, and sparse. Greedy matching takes the largest subset of a hex's domains first and
## consumes what it claims; ties break on the order here, so reordering this list is a gameplay
## change and not layout. A one-domain entry is the unclaimed-domain fallback.
@export var entries: Array[InfluenceEffectEntry] = []

## Added to a hex's effect set when a burgeon stack is at `Elevation.MAX_DEPTH` — the only thing
## here keyed on depth rather than on domains, and the only reason a melded area can be split by
## the depth-4 contour. Depth otherwise amplifies an effect instead of selecting one.
## https://github.com/snackpackgames/cosmicparade/issues/42
@export var ceiling_effect: InfluenceEffect
