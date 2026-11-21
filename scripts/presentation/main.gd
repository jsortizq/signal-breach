extends Node2D
## Composition root: loads levels, maps input actions to commands and
## pushes the resulting state to the views. No game rules live here —
## everything gameplay-related is in scripts/core, scripts/ai, scripts/systems.

const LEVELS: Array[String] = [
	"res://levels/level_01.json",
	"res://levels/level_02.json",
	"res://levels/level_03.json",
	"res://levels/level_04.json",
]

const MOVE_ACTIONS := {
	"move_up": "U",
	"move_down": "D",
	"move_left": "L",
	"move_right": "R",
	"wait": "W",
	"interact": "H",
}

const BOARD_AREA := Rect2(16, 16, 800, 688)

var _level_index := 0
var _level_data := {}
var _tp: TurnProcessor
var _board: BoardView
var _hud: Hud
var _debug: DebugOverlay


func _ready() -> void:
	_board = BoardView.new()
	add_child(_board)
	var ui := CanvasLayer.new()
	add_child(ui)
	_hud = Hud.new()
	ui.add_child(_hud)
	_debug = DebugOverlay.new()
	ui.add_child(_debug)
	_load_level(0)


func _load_level(index: int) -> void:
	_level_index = clampi(index, 0, LEVELS.size() - 1)
	_level_data = LevelLoader.load_file(LEVELS[_level_index])
	var errors := LevelLoader.validate(_level_data)
	for e in errors:
		push_error("%s: %s" % [LEVELS[_level_index], e])
	_tp = TurnProcessor.new(LevelLoader.build_state(_level_data))
	_refresh(true)
	# Centre the board inside its area.
	var size := _board.board_size()
	_board.position = (BOARD_AREA.position + (BOARD_AREA.size - size) * 0.5).floor()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if event.is_action_pressed("toggle_debug"):
		_debug.visible = not _debug.visible
		_board.show_debug = _debug.visible
	elif event.is_action_pressed("copy_replay"):
		DisplayServer.clipboard_set(_tp.replay_string())
		_hud.toast("Input log copied: %s" % _tp.replay_string())
	elif event.is_action_pressed("undo"):
		if _tp.undo():
			_refresh()
		else:
			_hud.toast("Nothing to undo")
	elif event.is_action_pressed("restart"):
		_tp.restart()
		_refresh(true)
	elif event.is_action_pressed("next_level"):
		if _tp.state.status == GameState.Status.WON or _debug.visible:
			_load_level(_level_index + 1)
	elif event.is_action_pressed("prev_level"):
		if _debug.visible:
			_load_level(_level_index - 1)
	else:
		for action in MOVE_ACTIONS:
			if event.is_action_pressed(action):
				_submit(MOVE_ACTIONS[action])
				return


func _submit(code: String) -> void:
	if _tp.state.status != GameState.Status.PLAYING:
		return
	if _tp.submit(CommandFactory.from_code(code)):
		_refresh()
	else:
		_hud.toast("Can't do that" if code != "H" else "No terminal next to you")


func _refresh(snap := false) -> void:
	_board.set_state(_tp.state, snap)
	_hud.refresh(_tp.state, _level_data.get("briefing", ""), _level_index, LEVELS.size())
	_debug.refresh(_tp.state, _tp.replay_string())
	get_window().title = "Signal Breach — %s" % _tp.state.level_name
