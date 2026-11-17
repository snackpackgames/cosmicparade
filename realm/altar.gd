class_name Altar
extends BoardPiece
## The Altar: a triangle-three gated on a level footprint, projecting nothing. It adds no members
## on purpose — no domain and no zone radius — so it inherits the null `zone_for` and can neither
## enter the influence tally nor read its own contribution.
## https://github.com/snackpackgames/cosmicparade/issues/77
