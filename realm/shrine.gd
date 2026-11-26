class_name Shrine
extends BoardPiece
## A shrine: one hex, freely placed, projecting a disc of whatever its vessel holds. The reach
## and the vessel are authored in `zone_source` as an `OfferingVessel`; what is in the vessel is
## per-placement state, held by the placeable's own copy, not on this shared resource.
## https://github.com/snackpackgames/cosmicparade/issues/74
## https://github.com/snackpackgames/cosmicparade/issues/75
