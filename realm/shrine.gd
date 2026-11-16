class_name Shrine
extends BoardPiece
## A shrine: one hex, a radius-2 disc, and no placement criteria at all. Single-hex because
## every multi-hex footprint at radius 2 projects 24-29 of the starting board's 37 hexes, the
## mush #52 rejected; criteria-free because the README has shrines "freely placed", and #30's
## demand that the criteria system be reused is met by reuse being *possible*, not by
## populating it.
##
## The radius is a `const` and not an `@export`: #74 settled one value for all shrines, and an
## exported field would invite a second. What the shrine projects is not here at all — the
## offering is per-placement runtime state, so `ShrinePlacement` answers for it.
## https://github.com/snackpackgames/cosmicparade/issues/74
## https://github.com/snackpackgames/cosmicparade/issues/75

const ZONE_RADIUS := 2
