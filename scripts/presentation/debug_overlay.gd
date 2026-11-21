class_name DebugOverlay
extends PanelContainer
## F1 panel for QA: FPS, full state summary, per-guard FSM table and the
## input log (F2 copies it) so any bug can be reproduced exactly.

var _label: Label
var _state: GameState
var _replay := ""


func _ready() -> void:
	visible = false
	position = Vector2(828, 448)
	custom_minimum_size = Vector2(436, 0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.04, 0.06, 0.88)
	style.border_color = Palette.PLAYER_CORE
	style.set_border_width_all(1)
	style.set_content_margin_all(10)
	add_theme_stylebox_override("panel", style)
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 11)
	_label.add_theme_color_override("font_color", Palette.TEXT)
	_label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	_label.custom_minimum_size = Vector2(416, 0)
	add_child(_label)


func refresh(state: GameState, replay: String) -> void:
	_state = state
	_replay = replay


func _process(_delta: float) -> void:
	if not visible or _state == null:
		return
	var lines := PackedStringArray()
	lines.append("DEBUG  ·  FPS %d  ·  turn %d  ·  %s" % [Engine.get_frames_per_second(), _state.turn, _state.status_name()])
	lines.append("player (%d,%d)   exit (%d,%d) %s" % [
		_state.player_pos.x, _state.player_pos.y, _state.exit_pos.x, _state.exit_pos.y,
		"unlocked" if _state.exit_unlocked() else "locked"])
	for g in _state.guards:
		lines.append("  %s" % g.summary())
	for c in _state.cameras:
		lines.append("  %s (period %d, range %d)" % [c.summary(), c.period, c.view_range])
	lines.append("camera_alert=%s   noise sources=%s" % [_state.camera_alert, str(_state.pending_noise)])
	lines.append("inputs: %s" % (_replay if _replay != "" else "(none)"))
	lines.append("summary: %s" % _state.summary())
	_label.text = "\n".join(lines)
