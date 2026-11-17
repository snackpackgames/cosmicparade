class_name Shrine
extends BoardPiece
## A shrine: one hex, freely placed, projecting a radius-2 disc of whatever its vessel holds.
## The radius is a const rather than an export because one value serves every shrine. What is in
## the vessel is per-placement state, so it lives on `ShrinePlacement`, not on this shared
## resource.
## https://github.com/snackpackgames/cosmicparade/issues/74
## https://github.com/snackpackgames/cosmicparade/issues/75

const ZONE_RADIUS := 2
