class_name HexCoordinates
extends RefCounted
## Flat-top axial hex geometry. CIRCUMRADIUS is the single source of truth for hex size.

const CIRCUMRADIUS := 1.0


static func distance(a: Vector2i, b: Vector2i) -> int:
	var delta := a - b
	@warning_ignore("integer_division")
	return (absi(delta.x) + absi(delta.y) + absi(delta.x + delta.y)) / 2


static func center_of(hex: Vector2i) -> Vector3:
	return Vector3(
		CIRCUMRADIUS * 1.5 * hex.x,
		0.0,
		CIRCUMRADIUS * sqrt(3.0) * (hex.y + hex.x * 0.5),
	)


static func corner_offsets() -> PackedVector3Array:
	var offsets := PackedVector3Array()
	for i in 6:
		var angle := deg_to_rad(60.0 * i)
		offsets.append(Vector3(CIRCUMRADIUS * cos(angle), 0.0, CIRCUMRADIUS * sin(angle)))
	return offsets
