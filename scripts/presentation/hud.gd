class_name Hud
extends Control
## Right-hand side panel: mission info, status, recent events, controls.

const PANEL_X := 840.0
const PANEL_W := 410.0

var _title: Label
var _level: Label
var _briefing: Label
var _stats: Label
var _status: Label
var _events: Label
var _controls: Label
var _toast: Label
var _toast_time := 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := VBoxContainer.new()
	box.position = Vector2(PANEL_X, 28)
	box.size = Vector2(PANEL_W, 660)
	box.add_theme_constant_override("separation", 10)
	add_child(box)

	_title = _label(box, "SIGNAL BREACH", 30, Palette.PLAYER_CORE)
	_level = _label(box, "", 20, Palette.TEXT)
	_briefing = _label(box, "", 14, Palette.TEXT_DIM)
	_briefing.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_briefing.custom_minimum_size = Vector2(PANEL_W, 0)
	_stats = _label(box, "", 16, Palette.TEXT)
	_status = _label(box, "", 22, Palette.TEXT)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size = Vector2(PANEL_W, 0)
	_events = _label(box, "", 13, Palette.TEXT_DIM)
	_events.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_events.custom_minimum_size = Vector2(PANEL_W, 90)
	_controls = _label(box,
		"Move: WASD / Arrows    Wait: Space    Hack: E\n" +
		"Undo: Z    Restart: R    Debug: F1    Copy replay: F2", 13, Palette.TEXT_DIM)

	_toast = _label(self, "", 16, Palette.OBJECTIVE)
	_toast.position = Vector2(32, 690)


func _label(parent: Node, text: String, size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	parent.add_child(l)
	return l


func refresh(state: GameState, briefing: String, level_index: int, level_count: int) -> void:
	_level.text = "Level %d/%d  ·  %s" % [level_index + 1, level_count, state.level_name]
	_briefing.text = briefing
	_stats.text = "Turn %d     Data %d/%d     Exit %s" % [
		state.turn, state.objectives_done(), state.objectives_total(),
		"OPEN" if state.exit_unlocked() else "LOCKED",
	]
	match state.status:
		GameState.Status.WON:
			var next := "Enter: next level" if level_index + 1 < level_count else "All levels cleared!"
			_set_status("ACCESS GRANTED — %s" % next, Palette.HACKED)
		GameState.Status.CAUGHT:
			_set_status("DETECTED — Z to undo, R to restart", Palette.DANGER)
		_:
			var alerted := state.guards.filter(func(g: GuardData) -> bool: return g.state == GuardData.State.ALERTED)
			if not alerted.is_empty():
				_set_status("ALERT — %d guard(s) hunting you" % alerted.size(), Palette.DANGER)
			elif state.camera_alert:
				_set_status("Camera alarm!", Palette.DANGER)
			else:
				_set_status("Undetected", Palette.TEXT)
	_events.text = "\n".join(state.events) if not state.events.is_empty() else "—"


func _set_status(text: String, col: Color) -> void:
	_status.text = text
	_status.add_theme_color_override("font_color", col)


func toast(text: String) -> void:
	_toast.text = text
	_toast_time = 1.6


func _process(delta: float) -> void:
	if _toast_time > 0.0:
		_toast_time -= delta
		_toast.modulate.a = clampf(_toast_time, 0.0, 1.0)
