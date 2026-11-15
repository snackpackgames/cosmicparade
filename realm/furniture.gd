class_name Furniture
extends GameData
## One authored furniture piece: the domain it projects, the footprint it occupies, the hex it
## arrives under, how far its influence reaches, and the gates on where it may be placed. What a
## piece projects is a property of the piece and never of where it sits.
## https://github.com/snackpackgames/cosmicparade/issues/51
## https://github.com/snackpackgames/cosmicparade/issues/52

@export var piece_name: String = ""
@export var domain: Domain.Kind = Domain.Kind.FOREST
@export var shape: Footprint.Shape = Footprint.Shape.SINGLE

## Which of the shape's own offsets the piece arrives under when taken from inventory.
@export var anchor: Vector2i = Vector2i.ZERO

## The radius of the discs its zone is grown from. 1 is the baseline.
@export var zone_radius: int = 1

@export var criteria: Array[PlacementCriterion] = []
