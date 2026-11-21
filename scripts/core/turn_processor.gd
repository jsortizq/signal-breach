class_name TurnProcessor
extends RefCounted
## Owns the current GameState, resolves turns and keeps the Undo history.
##
## Turn pipeline (strict order — tests/test_turns.gd locks it down):
##   0. Validate the command. Invalid -> rejected, no turn consumed.
##   1. Snapshot current state onto the history stack (for Undo).
##   2. PLAYER     execute the command; turn counter += 1.
##   3. VICTORY    on the exit with all objectives hacked -> WON (stop).
##   4. ENVIRONMENT cameras rotate (turn % period == 0).
##   5. SENSORS    enabled cameras that see the player raise an alarm.
##   6. PERCEPTION every guard perceives (vision, noise, alarm).
##   7. GUARDS     every guard acts in list order; a catch stops the turn.

var state: GameState
var command_log := PackedStringArray()
var _initial: GameState
var _history: Array[GameState] = []


func _init(initial_state: GameState) -> void:
	if initial_state == null:
		return # used by simulate()
	_initial = initial_state.clone()
	state = initial_state.clone()


## Returns true if the command was accepted and a turn was resolved.
func submit(cmd: Command) -> bool:
	if cmd == null or state.status != GameState.Status.PLAYING:
		return false
	if not cmd.can_execute(state):
		return false
	_history.append(state.clone())
	_begin_turn()
	cmd.execute(state)
	command_log.append(cmd.code)
	state.turn += 1
	_resolve_turn()
	return true


## Restores the state before the last accepted command. Works after being
## caught too, so the player can step back instead of restarting.
func undo() -> bool:
	if _history.is_empty():
		return false
	state = _history.pop_back()
	command_log.remove_at(command_log.size() - 1)
	return true


## Pure function: resolves one command on a copy of `from` without touching
## any history. Returns null if the command is invalid. Used by the solver.
static func simulate(from: GameState, cmd: Command) -> GameState:
	if from.status != GameState.Status.PLAYING or not cmd.can_execute(from):
		return null
	var tp := TurnProcessor.new(null)
	tp.state = from.clone()
	tp._begin_turn()
	cmd.execute(tp.state)
	tp.state.turn += 1
	tp._resolve_turn()
	return tp.state


func restart() -> void:
	state = _initial.clone()
	_history.clear()
	command_log.clear()


func can_undo() -> bool:
	return not _history.is_empty()


func replay_string() -> String:
	return "".join(command_log)


# ------------------------------------------------------------- internals

func _begin_turn() -> void:
	state.events.clear()
	state.pending_noise.clear()
	state.noise_cells.clear()
	state.camera_alert = false


func _resolve_turn() -> void:
	if _check_victory():
		return
	_environment_phase()
	_sensor_phase()
	var noise_maps := _collect_noise()
	for g in state.guards:
		GuardBrain.perceive(state, g, noise_maps)
	for g in state.guards:
		GuardBrain.act(state, g)
		if state.status == GameState.Status.CAUGHT:
			return


func _check_victory() -> bool:
	if state.player_pos == state.exit_pos and state.exit_unlocked():
		state.status = GameState.Status.WON
		state.log_event("Extraction complete")
		return true
	return false


func _environment_phase() -> void:
	for cam in state.cameras:
		if cam.enabled and cam.period > 0 and state.turn % cam.period == 0:
			cam.facing_index = (cam.facing_index + 1) % cam.facings.size()


func _sensor_phase() -> void:
	for cam in state.cameras:
		if cam.enabled and Vision.can_see(state, cam.pos, cam.facing(), cam.view_range, state.player_pos):
			state.camera_alert = true
			state.camera_alert_pos = state.player_pos
			state.log_event("Camera %s spotted the player!" % cam.id)
			return


func _collect_noise() -> Array:
	var maps := []
	for src in state.pending_noise:
		var map: Dictionary = NoiseSystem.propagate(state, src)
		maps.append({"source": src, "map": map})
		for cell in map:
			if not state.noise_cells.has(cell):
				state.noise_cells.append(cell)
	return maps
