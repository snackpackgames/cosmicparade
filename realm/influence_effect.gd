class_name InfluenceEffect
extends GameData
## One authored visual effect that projected domain influence produces — a shader or a particle
## effect, carrying no mechanics. Amplified by depth, so the intensity it is shown at is derived
## per hex and nothing about the amplification is authored here.
## https://github.com/snackpackgames/cosmicparade/issues/108
## https://github.com/snackpackgames/cosmicparade/issues/113
## https://github.com/snackpackgames/cosmicparade/issues/114

## Printed by the debug probe. Authored rather than taken from `Resource.resource_name`, which the
## engine never requires, or derived from the `.tres` path, which a rename breaks.
@export var effect_name: String = ""
