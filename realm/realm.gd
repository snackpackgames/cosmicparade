class_name Realm
extends Node3D
## Placeholder realm scene, reached with F6. Camera, lighting and the demo hexes are stubs
## like the title screen's; no interaction exists because the input verb is unsettled.

const DEMO_RADIUS := 3


func _ready() -> void:
	var hexes: Array[Vector2i] = []
	for q in range(-DEMO_RADIUS, DEMO_RADIUS + 1):
		for r in range(-DEMO_RADIUS, DEMO_RADIUS + 1):
			var hex := Vector2i(q, r)
			if HexCoordinates.distance(hex, Vector2i.ZERO) <= DEMO_RADIUS:
				hexes.append(hex)
	$RealmBoard.build(hexes)
