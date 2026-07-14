class_name HexGrid

# Hex placement lattice, sized to the sprites rather than to a true regular hex.
# The three offsets below are read straight off the artwork. Adjacent rows share
# their corners exactly when CAP + SIDE == ROW_HEIGHT, so SIDE is derived from the
# other two to keep that guarantee no matter what the sprites need.
const APOTHEM: int = 30  # centre to a left/right vertex (half the sprite width)
const CAP: int = 34  # centre to the top/bottom vertex (half the sprite height)
const ROW_HEIGHT: int = 54  # vertical spacing between rows, matched to the sprites
const SIDE: int = ROW_HEIGHT - CAP  # centre to a slanted vertex; closes the alignment
const ROW_SIZES: Array[int] = [3, 4, 5, 4, 3]

enum Dir { TOP, RIGHT_UP, RIGHT_DOWN, BOTTOM, LEFT_DOWN, LEFT_UP }

static func direction_vector(dir: Dir) -> Vector2:
	match dir:
		Dir.TOP: return Vector2(0, -CAP)
		Dir.RIGHT_UP: return Vector2(APOTHEM, -SIDE)
		Dir.RIGHT_DOWN: return Vector2(APOTHEM, SIDE)
		Dir.BOTTOM: return Vector2(0, CAP)
		Dir.LEFT_DOWN: return Vector2(-APOTHEM, SIDE)
		Dir.LEFT_UP: return Vector2(-APOTHEM, -SIDE)
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
	var offset := Vector2(APOTHEM * 5, ROW_HEIGHT * 2)
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
