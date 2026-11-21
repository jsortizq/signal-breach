# Reference solution: bug-01

## Root cause

`Vision.has_line_of_sight()` walks a Bresenham line from the viewer to the target and only
checks whether each **intermediate tile** is opaque. When the line steps diagonally, from
`(x, y)` to `(x+1, y-1)`, it goes from one tile to the next through a shared corner and never
visits the two orthogonal neighbours, `(x+1, y)` and `(x, y-1)`.

The Archives shelves are a diagonal "staircase" of wall tiles. Every 45° line that crosses
the staircase slips between two diagonal shelf tiles, so it never touches an opaque tile.

```
 . . #        viewer V, target T
 . # .        the line V -> T steps diagonally between the two #
 V . .        tiles and never visits either of them
```

## Fix

On every diagonal step, block the line if **both** orthogonal neighbours are opaque.
If only one is opaque, the line still passes, so looking past a single wall corner keeps working.

```diff
 static func has_line_of_sight(state: GameState, from: Vector2i, to: Vector2i) -> bool:
 	var cells := line_cells(from, to)
 	for i in range(1, cells.size()):
 		var prev := cells[i - 1]
 		var cur := cells[i]
+		# Diagonal step squeezing between two opaque tiles -> blocked.
+		if prev.x != cur.x and prev.y != cur.y:
+			if state.is_opaque(Vector2i(cur.x, prev.y)) and state.is_opaque(Vector2i(prev.x, cur.y)):
+				return false
 		# Intermediate tiles must be transparent; the target itself may not be.
 		if i < cells.size() - 1 and state.is_opaque(cur):
 			return false
 	return true
```

Diff between the branches: `git diff bug/01-vision-through-shelf-corners main -- scripts/systems/vision.gd`

## Why not other fixes

| Alternative | Problem |
|-------------|---------|
| Make the shelves 2 tiles thick in the level | Hides the symptom; any diagonal wall in a future level leaks again. The brief forbids editing the level. |
| Block if **either** neighbour is opaque | Too strict: guards could no longer see past the corner of a single wall, which changes vision across every level (level 04 breaks). |
| Switch to a "supercover" line (visit every tile the line touches) | Correct, but bigger and it changes which tiles count as visible at every distance, so the cones and the level balance change. |

## Verification done

- `LLLL` on level 02: g1 stays PATROL, no cone tiles behind the shelves (checked visually with F1).
- Reference solutions of all 4 levels: WON.
- Test suite: 37 passed, 0 failed.
