class_name HexGrid

# Pointy-top hex geometry snapped to an integer lattice. A regular hex needs an
# apothem of RADIUS * sqrt(3) / 2, which is irrational and forces rounding, so
# corners never sit on exact pixels and a corner shared by two tiles can round
# to two different keys. Snapping APOTHEM to an even integer keeps hexes
# near-regular while making every centre, corner and edge midpoint an exact,
# evenly spaced pixel.
const RADIUS: int = 34
const APOTHEM: int = 30
const ROW_HEIGHT: int = 54 # RADIUS * 1.5
const ROW_SIZES: Array[int] = [3, 4, 5, 4, 3]

enum Dir { TOP, RIGHT_UP, RIGHT_DOWN, BOTTOM, LEFT_DOWN, LEFT_UP }

static func direction_vector(dir: Dir) -> Vector2:
	match dir:
		Dir.TOP: return Vector2(0, -RADIUS)
		Dir.RIGHT_UP: return Vector2(APOTHEM, -RADIUS / 2.0)
		Dir.RIGHT_DOWN: return Vector2(APOTHEM, RADIUS / 2.0)
		Dir.BOTTOM: return Vector2(0, RADIUS)
		Dir.LEFT_DOWN: return Vector2(-APOTHEM, RADIUS / 2.0)
		Dir.LEFT_UP: return Vector2(-APOTHEM, -RADIUS / 2.0)
		_: return Vector2.ZERO

static func hex_position(index: int) -> Vector2:
	var row := 0
	var col := index
	for size in ROW_SIZES:
		if col < size:
			break
		col -= size
		row += 1
	var indent := 1 + absi(2 - row)
	var offset := Vector2(APOTHEM * 5, RADIUS * 3)
	return Vector2((indent + 2 * col) * APOTHEM, row * ROW_HEIGHT) - offset

static func corners(center: Vector2) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for dir in Dir.values():
		result.append(Vector2i((center + direction_vector(dir)).round()))
	return result

static func edges(center: Vector2) -> Dictionary[Vector2i, Array]:
	var result: Dictionary[Vector2i, Array] = {}
	var pts := corners(center)
	for i in pts.size():
		var a := Vector2(pts[i])
		var b := Vector2(pts[(i + 1) % pts.size()])
		var mid := Vector2i(((a + b) / 2.0).round())
		result[mid] = [a, b]
	return result
