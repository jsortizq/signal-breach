class_name GameState
extends RefCounted
## The complete, self-contained state of one level at one turn.
##
## Design rules:
##  * No engine nodes, no randomness, no time: the simulation is fully
##    deterministic, so an input sequence always produces the same state.
##  * clone() is a deep copy (except the immutable LevelGrid). The undo
##    history is a stack of these snapshots (Memento pattern).

enum Status { PLAYING, WON, CAUGHT }
const STATUS_NAMES: Array[String] = ["PLAYING", "WON", "CAUGHT"]

var level_name := ""
var grid: LevelGrid
var turn := 0
var status: int = Status.PLAYING
var player_pos := Vector2i.ZERO
var exit_pos := Vector2i.ZERO

## id -> { "pos": Vector2i, "open": bool }
var doors := {}
## id -> { "pos": Vector2i, "targets": Array[String], "objective": bool, "hacked": bool }
var terminals := {}
var guards: Array[GuardData] = []
var cameras: Array[CameraData] = []

# --- Per-turn transient data (rebuilt every turn, still cloned for Undo) ---
## Cells where noise was emitted this turn (set by commands).
var pending_noise: Array[Vector2i] = []
## Every cell reached by this turn's noise (debug overlay only).
var noise_cells: Array[Vector2i] = []
var camera_alert := false
var camera_alert_pos := Vector2i.ZERO
## Human-readable log of what happened this turn.
var events := PackedStringArray()


func clone() -> GameState:
	var s := GameState.new()
	s.level_name = level_name
	s.grid = grid # immutable, shared on purpose
	s.turn = turn
	s.status = status
	s.player_pos = player_pos
	s.exit_pos = exit_pos
	s.doors = doors.duplicate(true)
	s.terminals = terminals.duplicate(true)
	for g in guards:
		s.guards.append(g.clone())
	for c in cameras:
		s.cameras.append(c.clone())
	s.pending_noise = pending_noise.duplicate()
	s.noise_cells = noise_cells.duplicate()
	s.camera_alert = camera_alert
	s.camera_alert_pos = camera_alert_pos
	s.events = events.duplicate()
	return s


# ---------------------------------------------------------------- queries

func door_at(c: Vector2i) -> String:
	for id in doors:
		if doors[id]["pos"] == c:
			return id
	return ""


func terminal_at(c: Vector2i) -> String:
	for id in terminals:
		if terminals[id]["pos"] == c:
			return id
	return ""


func guard_at(c: Vector2i) -> GuardData:
	for g in guards:
		if g.pos == c:
			return g
	return null


func is_closed_door(c: Vector2i) -> bool:
	var id := door_at(c)
	return id != "" and not doors[id]["open"]


## Blocks line of sight and sound: walls and closed doors.
func is_opaque(c: Vector2i) -> bool:
	return grid.is_wall(c) or is_closed_door(c)


## Static walkability shared by player and guards (ignores units).
func is_passable(c: Vector2i) -> bool:
	return not is_opaque(c) and terminal_at(c) == ""


func is_walkable_for_player(c: Vector2i) -> bool:
	return is_passable(c) and guard_at(c) == null


func objectives_total() -> int:
	var n := 0
	for id in terminals:
		if terminals[id]["objective"]:
			n += 1
	return n


func objectives_done() -> int:
	var n := 0
	for id in terminals:
		if terminals[id]["objective"] and terminals[id]["hacked"]:
			n += 1
	return n


func exit_unlocked() -> bool:
	return objectives_done() == objectives_total()


func status_name() -> String:
	return STATUS_NAMES[status]


func log_event(text: String) -> void:
	events.append(text)


# ---------------------------------------------------------- serialisation

## Deterministic one-line description of the gameplay-relevant state.
## Used by tests, the debug overlay and task acceptance criteria.
func summary() -> String:
	var parts := PackedStringArray()
	parts.append("t=%d" % turn)
	parts.append(status_name())
	parts.append("p=(%d,%d)" % [player_pos.x, player_pos.y])
	parts.append("obj=%d/%d" % [objectives_done(), objectives_total()])
	var ids := doors.keys()
	ids.sort()
	for id in ids:
		parts.append("%s:%s" % [id, "open" if doors[id]["open"] else "closed"])
	for g in guards:
		parts.append(g.summary())
	for c in cameras:
		parts.append(c.summary())
	return " | ".join(parts)


## Key used by the solver to detect repeated states. Turn number is folded
## modulo 12 because only camera rotation depends on it (periods 1..4).
func state_key() -> String:
	var full := summary()
	return "%d#%s" % [turn % 12, full.substr(full.find("|"))]
