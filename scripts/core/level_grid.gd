class_name LevelGrid
extends RefCounted
## Static level layout (walls, floor, noisy tiles, exit).
##
## Immutable after construction, so it is SHARED between GameState snapshots
## instead of being cloned on every turn. Anything that can change during play
## (doors, terminals, units) lives in GameState.

enum Tile { FLOOR, WALL, NOISY, EXIT }

var width := 0
var height := 0
var _tiles := PackedInt32Array()


func _init(rows: PackedStringArray) -> void:
	height = rows.size()
	for row in rows:
		width = maxi(width, row.length())
	_tiles.resize(width * height)
	for y in height:
		var row: String = rows[y]
		for x in width:
			var ch := row[x] if x < row.length() else "#"
			_tiles[y * width + x] = _char_to_tile(ch)


static func _char_to_tile(ch: String) -> int:
	match ch:
		"#":
			return Tile.WALL
		"~":
			return Tile.NOISY
		"E":
			return Tile.EXIT
		_:
			# '.', 'P' and any object marker sit on plain floor.
			return Tile.FLOOR


func in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < width and c.y < height


## Out-of-bounds cells behave like walls, so callers never need bounds checks.
func tile_at(c: Vector2i) -> int:
	if not in_bounds(c):
		return Tile.WALL
	return _tiles[c.y * width + c.x]


func is_wall(c: Vector2i) -> bool:
	return tile_at(c) == Tile.WALL


func is_noisy(c: Vector2i) -> bool:
	return tile_at(c) == Tile.NOISY


func is_exit(c: Vector2i) -> bool:
	return tile_at(c) == Tile.EXIT
