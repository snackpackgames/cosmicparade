class_name Realm
extends Node3D
## Placeholder realm scene, reached with F6. Camera and lighting are stubs like the title
## screen's; no interaction exists because the input verb is unsettled. The board's extent comes
## from the realm geometry, which is where growth lives.

var geometry := RealmGeometry.new()


func _ready() -> void:
	$RealmBoard.build(geometry.hexes())
