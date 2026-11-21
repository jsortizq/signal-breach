class_name Vision
extends RefCounted
## Grid vision: a 90-degree cone in front of the viewer, truncated at
## `view_range` tiles forward, with Bresenham line of sight.
##
## Edge cases handled (covered by tests/test_vision.gd):
##  * The viewer's own tile never blocks (cameras are mounted on walls).
##  * The target tile itself may be opaque (you can "see" a wall).
##  * Diagonal corner gaps: a line stepping diagonally between two opaque
##    tiles is blocked, so guards cannot see through wall corners.
##  * Closed doors are opaque; open doors are transparent.


## Cone test only (no occlusion). Cells on the 45-degree diagonals count.
static func in_cone(origin: Vector2i, facing: Vector2i, cell: Vector2i, view_range: int) -> bool:
	var d := cell - origin
	var forward := d.x * facing.x + d.y * facing.y
	if forward <= 0 or forward > view_range:
		return false
	var lateral := absi(d.x * facing.y - d.y * facing.x)
	return lateral <= forward


## Bresenham line, both endpoints included, ordered from `a` to `b`.
static func line_cells(a: Vector2i, b: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var x := a.x
	var y := a.y
	var dx := absi(b.x - a.x)
	var dy := -absi(b.y - a.y)
	var sx := 1 if a.x < b.x else -1
	var sy := 1 if a.y < b.y else -1
	var err := dx + dy
	while true:
		out.append(Vector2i(x, y))
		if x == b.x and y == b.y:
			break
		var e2 := 2 * err
		if e2 >= dy:
			err += dy
			x += sx
		if e2 <= dx:
			err += dx
			y += sy
	return out


static func has_line_of_sight(state: GameState, from: Vector2i, to: Vector2i) -> bool:
	var cells := line_cells(from, to)
	for i in range(1, cells.size()):
		var prev := cells[i - 1]
		var cur := cells[i]
		# Diagonal step squeezing between two opaque tiles -> blocked.
		if prev.x != cur.x and prev.y != cur.y:
			if state.is_opaque(Vector2i(cur.x, prev.y)) and state.is_opaque(Vector2i(prev.x, cur.y)):
				return false
		# Intermediate tiles must be transparent; the target itself may not be.
		if i < cells.size() - 1 and state.is_opaque(cur):
			return false
	return true


static func can_see(state: GameState, origin: Vector2i, facing: Vector2i, view_range: int, target: Vector2i) -> bool:
	return in_cone(origin, facing, target, view_range) and has_line_of_sight(state, origin, target)


## All non-wall tiles currently visible. Used for rendering cones and by the
## debug overlay; gameplay checks use can_see() directly.
static func visible_cells(state: GameState, origin: Vector2i, facing: Vector2i, view_range: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y in range(origin.y - view_range, origin.y + view_range + 1):
		for x in range(origin.x - view_range, origin.x + view_range + 1):
			var c := Vector2i(x, y)
			if not state.grid.in_bounds(c) or state.is_opaque(c):
				continue
			if can_see(state, origin, facing, view_range, c):
				out.append(c)
	return out
