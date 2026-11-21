class_name Dir
extends RefCounted
## Grid direction helpers. Y grows downward (screen space).

const N := Vector2i(0, -1)
const E := Vector2i(1, 0)
const S := Vector2i(0, 1)
const W := Vector2i(-1, 0)

## Canonical neighbour order. Every search uses this order so that
## tie-breaks are deterministic across runs and platforms.
const ORDER: Array[Vector2i] = [N, E, S, W]

const _NAMES := {"N": N, "E": E, "S": S, "W": W}


static func from_name(dir_name: String) -> Vector2i:
	assert(_NAMES.has(dir_name), "Unknown direction: %s" % dir_name)
	return _NAMES[dir_name]


static func to_name(d: Vector2i) -> String:
	for key in _NAMES:
		if _NAMES[key] == d:
			return key
	return "?"


## Clockwise rotation: N -> E -> S -> W -> N.
static func rotate_cw(d: Vector2i) -> Vector2i:
	return Vector2i(-d.y, d.x)


static func manhattan(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)
