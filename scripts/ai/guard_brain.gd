class_name GuardBrain
extends RefCounted
## Finite state machine for guards. Stateless: all data lives in GuardData,
## which keeps Undo trivial (snapshots) and the AI unit-testable.
##
##   PATROL ──sees player far / hears noise──▶ SUSPICIOUS
##   PATROL ──sees player within 2 / camera alarm──▶ ALERTED
##   SUSPICIOUS ──sees player / camera alarm──▶ ALERTED
##   SUSPICIOUS ──search finished──▶ PATROL
##   ALERTED ──no sight for 3 turns──▶ SUSPICIOUS (at last known position)
##   ALERTED + orthogonally adjacent to player ──▶ player CAUGHT
##
## Each turn is split in two passes run by TurnProcessor:
##   1. perceive() for ALL guards (simultaneous perception of the same world)
##   2. act() for each guard in list order (movement, catching)

const VIEW_RANGE := 4
const CLOSE_RANGE := 2
const SEARCH_TURNS := 2
const LOSE_SIGHT_TURNS := 3


## `noise_maps` = Array of { "source": Vector2i, "map": Dictionary } from Noise.
static func perceive(state: GameState, g: GuardData, noise_maps: Array) -> void:
	var player := state.player_pos
	var sees := Vision.can_see(state, g.pos, g.facing, VIEW_RANGE, player)
	var heard: Variant = _loudest_noise(g, noise_maps)
	var heard_something: bool = heard != null

	match g.state:
		GuardData.State.PATROL:
			if sees:
				if Dir.manhattan(g.pos, player) <= CLOSE_RANGE:
					_alert(state, g, player, "spotted player up close")
				else:
					_suspect(state, g, player, "glimpsed player")
			elif state.camera_alert:
				_alert(state, g, state.camera_alert_pos, "camera alarm")
			elif heard_something:
				_suspect(state, g, heard, "heard noise")
		GuardData.State.SUSPICIOUS:
			if sees:
				_alert(state, g, player, "confirmed player")
			elif state.camera_alert:
				_alert(state, g, state.camera_alert_pos, "camera alarm")
			elif heard_something:
				g.target = heard
				g.timer = SEARCH_TURNS
				state.log_event("%s: new noise, re-targeting (%d,%d)" % [g.id, heard.x, heard.y])
		GuardData.State.ALERTED:
			if sees:
				g.target = player
				g.lost_sight = 0
			elif state.camera_alert:
				g.target = state.camera_alert_pos
				g.lost_sight = 0
			else:
				g.lost_sight += 1
				if g.lost_sight >= LOSE_SIGHT_TURNS:
					_suspect(state, g, g.target, "lost the player")


static func act(state: GameState, g: GuardData) -> void:
	match g.state:
		GuardData.State.PATROL:
			if g.route.is_empty():
				return
			if g.pos == g.route[g.route_index]:
				g.route_index = (g.route_index + 1) % g.route.size()
			_step_toward(state, g, g.route[g.route_index])
		GuardData.State.SUSPICIOUS:
			var arrived := g.pos == g.target or not Pathfinding.is_reachable(state, g.pos, g.target)
			if not arrived:
				_step_toward(state, g, g.target)
				return
			# Look around: rotate clockwise once per turn, then give up.
			g.facing = Dir.rotate_cw(g.facing)
			g.timer -= 1
			if g.timer <= 0:
				g.state = GuardData.State.PATROL
				state.log_event("%s: SUSPICIOUS -> PATROL (nothing found)" % g.id)
		GuardData.State.ALERTED:
			if Dir.manhattan(g.pos, state.player_pos) == 1:
				g.facing = state.player_pos - g.pos
				state.status = GameState.Status.CAUGHT
				state.log_event("%s caught the player!" % g.id)
				return
			_step_toward(state, g, g.target)


# ---------------------------------------------------------------- helpers

static func _alert(state: GameState, g: GuardData, at: Vector2i, reason: String) -> void:
	state.log_event("%s: %s -> ALERTED (%s)" % [g.id, g.state_name(), reason])
	g.state = GuardData.State.ALERTED
	g.target = at
	g.lost_sight = 0


static func _suspect(state: GameState, g: GuardData, at: Vector2i, reason: String) -> void:
	state.log_event("%s: %s -> SUSPICIOUS (%s at (%d,%d))" % [g.id, g.state_name(), reason, at.x, at.y])
	g.state = GuardData.State.SUSPICIOUS
	g.target = at
	g.timer = SEARCH_TURNS


## Closest noise source this guard can hear, or null.
static func _loudest_noise(g: GuardData, noise_maps: Array) -> Variant:
	var best: Variant = null
	var best_dist := 1 << 30
	for entry in noise_maps:
		var map: Dictionary = entry["map"]
		if map.has(g.pos) and map[g.pos] < best_dist:
			best_dist = map[g.pos]
			best = entry["source"]
	return best


## Moves one tile toward `goal`. Returns false when blocked or already there.
## A guard never walks into another unit; it turns to face it instead.
static func _step_toward(state: GameState, g: GuardData, goal: Vector2i) -> bool:
	var step := Pathfinding.next_step(state, g.pos, goal)
	if step == g.pos:
		return false
	g.facing = step - g.pos
	if step == state.player_pos or state.guard_at(step) != null:
		return false
	g.pos = step
	return true
