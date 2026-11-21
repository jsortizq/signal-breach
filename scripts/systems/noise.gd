class_name NoiseSystem
extends RefCounted
## Sound propagates like a flood fill: it travels around corners but not
## through walls or closed doors. Distance is measured in steps, not in a
## straight line, so a guard on the other side of a wall may not hear a
## noise that is geometrically close.

const RADIUS := 4


## Returns { Vector2i cell: int steps } for every cell the noise reaches.
static func propagate(state: GameState, source: Vector2i, radius: int = RADIUS) -> Dictionary:
	var dist := {source: 0}
	var frontier: Array[Vector2i] = [source]
	while not frontier.is_empty():
		var cur: Vector2i = frontier.pop_front()
		var d: int = dist[cur]
		if d >= radius:
			continue
		for dir in Dir.ORDER:
			var nxt: Vector2i = cur + dir
			if dist.has(nxt) or state.is_opaque(nxt):
				continue
			dist[nxt] = d + 1
			frontier.append(nxt)
	return dist
