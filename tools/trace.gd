extends SceneTree
## Prints the state after every turn of an input sequence, plus an ASCII
## board of the final state. Handy for writing acceptance criteria.
##
## Usage:
##   godot --headless --path . --script res://tools/trace.gd -- res://levels/level_01.json DRRRD
##   add "--board" as third argument to print the board after every turn.


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 1:
		print("usage: -- <level.json> [inputs] [--board]")
		quit(2)
		return
	var data := LevelLoader.load_file(args[0])
	var inputs := args[1] if args.size() > 1 else ""
	var every_turn := args.has("--board")
	var tp := TurnProcessor.new(LevelLoader.build_state(data))
	print("start  ", tp.state.summary())
	print(render(tp.state))
	for token in inputs:
		var accepted := tp.undo() if token == "Z" else tp.submit(CommandFactory.from_code(token))
		print("%s %s  %s" % [token, "  " if accepted else "✗ (rejected)", tp.state.summary()])
		if accepted:
			for e in tp.state.events:
				print("        · ", e)
			if every_turn:
				print(render(tp.state))
	print(render(tp.state))
	quit()


## ASCII board. Legend: @ player, G/S/A guard (patrol/suspicious/alerted),
## C camera, T terminal (t = hacked), D door (d = open), * seen by a guard.
static func render(s: GameState) -> String:
	var seen := {}
	for g in s.guards:
		for c in Vision.visible_cells(s, g.pos, g.facing, GuardBrain.VIEW_RANGE):
			seen[c] = true
	for cam in s.cameras:
		if cam.enabled:
			for c in Vision.visible_cells(s, cam.pos, cam.facing(), cam.view_range):
				seen[c] = true
	var lines := PackedStringArray()
	for y in s.grid.height:
		var line := ""
		for x in s.grid.width:
			var c := Vector2i(x, y)
			var ch := "."
			match s.grid.tile_at(c):
				LevelGrid.Tile.WALL:
					ch = "#"
				LevelGrid.Tile.NOISY:
					ch = "~"
				LevelGrid.Tile.EXIT:
					ch = "E"
			if seen.has(c) and ch != "#":
				ch = "*"
			var door := s.door_at(c)
			if door != "":
				ch = "d" if s.doors[door]["open"] else "D"
			var term := s.terminal_at(c)
			if term != "":
				ch = "t" if s.terminals[term]["hacked"] else "T"
			for cam in s.cameras:
				if cam.pos == c:
					ch = "C"
			var g := s.guard_at(c)
			if g != null:
				ch = ["G", "S", "A"][g.state]
			if s.player_pos == c:
				ch = "@"
			line += ch
		lines.append(line)
	return "\n".join(lines)
