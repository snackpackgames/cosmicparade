class_name HexCoordinates
extends RefCounted
## Flat-top axial hex geometry. CIRCUMRADIUS is the single source of truth for hex size.

const CIRCUMRADIUS := 1.0

## The six unit steps, in rotation order: one 60-degree step walks this list forward.
const DIRECTIONS: Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(1, -1),
	Vector2i(0, -1),
	Vector2i(-1, 0),
	Vector2i(-1, 1),
	Vector2i(0, 1),
]


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


static func neighbors(hex: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for direction in DIRECTIONS:
		result.append(hex + direction)
	return result


static func rotate(hex: Vector2i, steps: int) -> Vector2i:
	# One 60-degree step about the origin, applied posmod(steps, 6) times.
	var turned := hex
	for _step in posmod(steps, 6):
		turned = Vector2i(turned.x + turned.y, -turned.x)
	return turned


static func disc(center: Vector2i, radius: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for q in range(center.x - radius, center.x + radius + 1):
		for r in range(center.y - radius, center.y + radius + 1):
			var hex := Vector2i(q, r)
			if distance(center, hex) <= radius:
				result.append(hex)
	return result


static func ring(center: Vector2i, radius: int) -> Array[Vector2i]:
	if radius == 0:
		return [center] as Array[Vector2i]
	var result: Array[Vector2i] = []
	for hex in disc(center, radius):
		if distance(center, hex) == radius:
			result.append(hex)
	return result
