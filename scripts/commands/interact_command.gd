class_name InteractCommand
extends Command
## Hacks an orthogonally adjacent, not-yet-hacked terminal.
## If several qualify, the first in Dir.ORDER (N, E, S, W) wins.
## Hacking applies the terminal's targets: doors open, cameras shut down.


func _init() -> void:
	code = "H"


func can_execute(state: GameState) -> bool:
	return _find_terminal(state) != ""


func execute(state: GameState) -> void:
	var id := _find_terminal(state)
	var term: Dictionary = state.terminals[id]
	term["hacked"] = true
	state.log_event("Hacked terminal %s" % id)
	for target_id in term["targets"]:
		if state.doors.has(target_id):
			state.doors[target_id]["open"] = true
			state.log_event("  door %s opened" % target_id)
		else:
			for cam in state.cameras:
				if cam.id == target_id:
					cam.enabled = false
					state.log_event("  camera %s disabled" % target_id)


func _find_terminal(state: GameState) -> String:
	for dir in Dir.ORDER:
		var id := state.terminal_at(state.player_pos + dir)
		if id != "" and not state.terminals[id]["hacked"]:
			return id
	return ""
