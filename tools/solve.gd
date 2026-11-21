extends SceneTree
## A* solver over the deterministic simulation.
## Proves every level is solvable and finds a near-shortest input sequence
## (the heuristic is admissible: it ignores walls, doors and guards).
##
## Usage:
##   godot --headless --path . --script res://tools/solve.gd -- res://levels/level_01.json
## With no argument, solves every level in res://levels/.

const MAX_STATES := 300000
const CODES := "UDLRWH"


func _init() -> void:
	var paths := PackedStringArray()
	for arg in OS.get_cmdline_user_args():
		paths.append(arg)
	if paths.is_empty():
		var files := DirAccess.get_files_at("res://levels")
		files.sort()
		for f in files:
			if f.ends_with(".json"):
				paths.append("res://levels/" + f)
	var ok := true
	for path in paths:
		var data := LevelLoader.load_file(path)
		var t0 := Time.get_ticks_msec()
		var result := solve(LevelLoader.build_state(data))
		var ms := Time.get_ticks_msec() - t0
		if result["solution"] == null:
			ok = false
			print("%s: NO SOLUTION (explored %d states, %d ms)" % [path, result["explored"], ms])
		else:
			var sol: String = result["solution"]
			print("%s: %d moves  %s  (explored %d states, %d ms)" % [path, sol.length(), sol, result["explored"], ms])
	quit(0 if ok else 1)


## Lower bound on remaining moves.
static func heuristic(s: GameState) -> int:
	var best := 1 << 30
	var pending: Array[Vector2i] = []
	for id in s.terminals:
		var t: Dictionary = s.terminals[id]
		if t["objective"] and not t["hacked"]:
			pending.append(t["pos"])
	if pending.is_empty():
		return Dir.manhattan(s.player_pos, s.exit_pos)
	for p in pending:
		# reach a tile next to it (>= dist-1), hack (1), then go to the exit
		var h := maxi(Dir.manhattan(s.player_pos, p) - 1, 0) + 1 + maxi(Dir.manhattan(p, s.exit_pos) - 1, 0)
		best = mini(best, h)
	return best


func solve(start: GameState) -> Dictionary:
	var heap := MinHeap.new()
	var best_g := {start.state_key(): 0}
	heap.push(heuristic(start), [start, ""])
	var explored := 0
	while not heap.is_empty() and explored < MAX_STATES:
		var node: Array = heap.pop()
		var state: GameState = node[0]
		var path: String = node[1]
		explored += 1
		for code in CODES:
			var next := TurnProcessor.simulate(state, CommandFactory.from_code(code))
			if next == null or next.status == GameState.Status.CAUGHT:
				continue
			var npath := path + code
			if next.status == GameState.Status.WON:
				return {"solution": npath, "explored": explored}
			var key := next.state_key()
			if best_g.has(key) and best_g[key] <= npath.length():
				continue
			best_g[key] = npath.length()
			heap.push(npath.length() + heuristic(next), [next, npath])
	return {"solution": null, "explored": explored}


class MinHeap:
	var _keys: Array[int] = []
	var _items: Array = []

	func is_empty() -> bool:
		return _keys.is_empty()

	func push(key: int, item: Variant) -> void:
		_keys.append(key)
		_items.append(item)
		var i := _keys.size() - 1
		while i > 0:
			var parent := (i - 1) / 2
			if _keys[parent] <= _keys[i]:
				break
			_swap(i, parent)
			i = parent

	func pop() -> Variant:
		var top: Variant = _items[0]
		var last := _keys.size() - 1
		_swap(0, last)
		_keys.pop_back()
		_items.pop_back()
		var i := 0
		var n := _keys.size()
		while true:
			var l := 2 * i + 1
			var r := l + 1
			var m := i
			if l < n and _keys[l] < _keys[m]:
				m = l
			if r < n and _keys[r] < _keys[m]:
				m = r
			if m == i:
				break
			_swap(i, m)
			i = m
		return top

	func _swap(a: int, b: int) -> void:
		var k := _keys[a]
		_keys[a] = _keys[b]
		_keys[b] = k
		var it: Variant = _items[a]
		_items[a] = _items[b]
		_items[b] = it
