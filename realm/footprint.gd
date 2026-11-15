class_name Footprint
extends RefCounted
## The closed vocabulary of footprint shapes: the complete set of polyhexes up to size 3. There
## is no sixth shape and none may be added — a piece authors a choice from this vocabulary, never
## a shape of its own. Footprints never overlap; influence does.
## https://github.com/snackpackgames/cosmicparade/issues/51

enum Shape {SINGLE, PAIR, STRAIGHT, BEND, TRIANGLE}

## Canonical offsets per shape, anchored at (0, 0). The bend's ends are 2 apart and not
## collinear, which is the only thing distinguishing it from the straight.
const OFFSETS := {
	Shape.SINGLE: [Vector2i(0, 0)],
	Shape.PAIR: [Vector2i(0, 0), Vector2i(1, 0)],
	Shape.STRAIGHT: [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)],
	Shape.BEND: [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, -1)],
	Shape.TRIANGLE: [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, -1)],
}


## A copy, so a caller cannot mutate the vocabulary.
static func offsets_for(shape: Shape) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	result.assign(OFFSETS[shape])
	return result


## The hexes a piece of this shape occupies when its grab hex is dropped on the target. The
## pivot is the grab hex, so the grabbed hex lands on the target at every orientation and a
## turning piece never swings out from under the cursor.
## https://github.com/snackpackgames/cosmicparade/issues/56
static func occupied(
	shape: Shape, orientation: int, target: Vector2i, grab_offset: Vector2i
) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for offset in offsets_for(shape):
		result.append(target + HexCoordinates.rotate(offset - grab_offset, orientation))
	return result
