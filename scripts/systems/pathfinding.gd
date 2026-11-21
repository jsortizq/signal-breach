class_name Pathfinding
extends RefCounted
## Breadth-first search on the 4-connected grid. Grids are tiny (<= 16x12),
## so BFS is simpler and just as fast as A* here, and it is trivially
## deterministic thanks to the fixed neighbour order in Dir.ORDER.
##
## Units (guards, player) are ignored while searching; the caller decides
## what to do when the first step is occupied. The goal cell is accepted
## even if it is not passable (e.g. chasing towards the player's tile).


## First step from `from` towards `to`, or `from` if already there / no path.
static func next_step(state: GameState, from: Vector2i, to: Vector2i) -> Vector2i:
	if from == to:
		return from
	var parent := {from: from}
	var frontier: Array[Vector2i] = [from]
	while not frontier.is_empty():
		var cur: Vector2i = frontier.pop_front()
		for dir in Dir.ORDER:
			var nxt: Vector2i = cur + dir
			if parent.has(nxt):
				continue
			if nxt != to and not state.is_passable(nxt):
				continue
			parent[nxt] = cur
			if nxt == to:
				return _first_step(parent, from, to)
			frontier.append(nxt)
	return from


static func is_reachable(state: GameState, from: Vector2i, to: Vector2i) -> bool:
	return from == to or next_step(state, from, to) != from


static func _first_step(parent: Dictionary, from: Vector2i, to: Vector2i) -> Vector2i:
	var cur := to
	while parent[cur] != from:
		cur = parent[cur]
	return cur
