class_name BoardView
extends Node2D
## Renders a GameState with immediate-mode drawing (no art assets needed).
## Read-only: it never mutates the state. Units are smoothly interpolated
## towards their logical tile so turns feel responsive without affecting
## the deterministic simulation.

const TILE := 48

var state: GameState
var show_debug := false

var _visual := {}          # unit key -> Vector2 (tile space, interpolated)
var _guard_cones := {}     # guard id -> Array[Vector2i]
var _camera_cones := {}    # camera id -> Array[Vector2i]
var _pulse := 0.0          # 0..1, restarted on every accepted turn
var _font: Font


func _ready() -> void:
	_font = ThemeDB.fallback_font


func set_state(s: GameState, snap := false) -> void:
	state = s
	if snap:
		_visual.clear()
	_pulse = 1.0
	_guard_cones.clear()
	_camera_cones.clear()
	for g in s.guards:
		_guard_cones[g.id] = Vision.visible_cells(s, g.pos, g.facing, GuardBrain.VIEW_RANGE)
	for cam in s.cameras:
		if cam.enabled:
			_camera_cones[cam.id] = Vision.visible_cells(s, cam.pos, cam.facing(), cam.view_range)
	queue_redraw()


func board_size() -> Vector2:
	if state == null:
		return Vector2.ZERO
	return Vector2(state.grid.width, state.grid.height) * TILE


func _process(delta: float) -> void:
	if state == null:
		return
	_animate("player", state.player_pos, delta)
	for g in state.guards:
		_animate(g.id, g.pos, delta)
	_pulse = maxf(_pulse - delta * 1.6, 0.0)
	queue_redraw()


func _animate(key: String, tile: Vector2i, delta: float) -> void:
	var target := Vector2(tile)
	if not _visual.has(key):
		_visual[key] = target
		return
	_visual[key] = (_visual[key] as Vector2).lerp(target, 1.0 - exp(-delta * 18.0))


func _center(tile_pos: Vector2) -> Vector2:
	return tile_pos * TILE + Vector2(TILE, TILE) * 0.5


func _rect(c: Vector2i, inset := 0.0) -> Rect2:
	return Rect2(Vector2(c) * TILE + Vector2(inset, inset), Vector2(TILE, TILE) - Vector2(inset, inset) * 2.0)


# ------------------------------------------------------------------ draw

func _draw() -> void:
	if state == null:
		return
	_draw_tiles()
	_draw_cones()
	_draw_noise()
	_draw_objects()
	_draw_guards()
	_draw_player()
	if show_debug:
		_draw_debug()


func _draw_tiles() -> void:
	for y in state.grid.height:
		for x in state.grid.width:
			var c := Vector2i(x, y)
			var r := _rect(c)
			match state.grid.tile_at(c):
				LevelGrid.Tile.WALL:
					draw_rect(r, Palette.WALL)
					draw_rect(Rect2(r.position, Vector2(TILE, 6)), Palette.WALL_TOP)
				LevelGrid.Tile.NOISY:
					draw_rect(r, Palette.NOISY)
					for i in range(0, TILE, 8):
						draw_line(r.position + Vector2(i, 0), r.position + Vector2(0, i), Palette.NOISY_HATCH, 1.0)
						draw_line(r.position + Vector2(TILE, i), r.position + Vector2(i, TILE), Palette.NOISY_HATCH, 1.0)
				LevelGrid.Tile.EXIT:
					var col := Palette.EXIT_OPEN if state.exit_unlocked() else Palette.EXIT_LOCKED
					draw_rect(r, Palette.FLOOR)
					draw_rect(_rect(c, 5), col, false, 3.0)
					_text(r.position + Vector2(0, TILE * 0.62), "EXIT", 12, col)
				_:
					draw_rect(r, Palette.FLOOR)
					draw_rect(r, Palette.FLOOR_LINE, false, 1.0)


func _draw_cones() -> void:
	for g in state.guards:
		for c in _guard_cones.get(g.id, []):
			draw_rect(_rect(c, 1), Palette.CONE[g.state])
	for id in _camera_cones:
		for c in _camera_cones[id]:
			draw_rect(_rect(c, 1), Palette.CAMERA_CONE)
	if state.camera_alert:
		var p := _center(Vector2(state.camera_alert_pos))
		draw_arc(p, TILE * 0.45, 0, TAU, 32, Palette.DANGER, 3.0)


func _draw_noise() -> void:
	if _pulse <= 0.0:
		return
	for src in state.pending_noise:
		var p := _center(Vector2(src))
		var radius := (1.0 - _pulse) * NoiseSystem.RADIUS * TILE
		draw_arc(p, radius, 0, TAU, 48, Color(1, 1, 1, _pulse * 0.6), 2.0)


func _draw_objects() -> void:
	for id in state.doors:
		var d: Dictionary = state.doors[id]
		if d["open"]:
			draw_rect(_rect(d["pos"], 4), Palette.DOOR.darkened(0.4), false, 2.0)
		else:
			var r := _rect(d["pos"], 3)
			draw_rect(r, Palette.DOOR)
			for i in 3:
				var y := r.position.y + 8 + i * 12
				draw_line(Vector2(r.position.x + 4, y), Vector2(r.end.x - 4, y), Palette.DOOR.darkened(0.45), 3.0)
	for id in state.terminals:
		var t: Dictionary = state.terminals[id]
		var col := Palette.HACKED if t["hacked"] else (Palette.OBJECTIVE if t["objective"] else Palette.TERMINAL)
		draw_rect(_rect(t["pos"], 7), Palette.BG)
		draw_rect(_rect(t["pos"], 7), col, false, 2.0)
		draw_rect(_rect(t["pos"], 15), col if t["hacked"] else col.darkened(0.5))
		_text(Vector2(t["pos"]) * TILE + Vector2(0, TILE - 2), id, 10, col)
	for cam in state.cameras:
		var p := _center(Vector2(cam.pos))
		var col := Palette.CAMERA if cam.enabled else Palette.TEXT_DIM
		draw_rect(Rect2(p - Vector2(10, 10), Vector2(20, 20)), Palette.BG)
		draw_circle(p, 7, col)
		if cam.enabled:
			draw_line(p, p + Vector2(cam.facing()) * 18, col, 4.0)
		else:
			draw_line(p - Vector2(8, 8), p + Vector2(8, 8), Palette.DANGER, 2.0)
			draw_line(p + Vector2(-8, 8), p + Vector2(8, -8), Palette.DANGER, 2.0)


func _draw_guards() -> void:
	for g in state.guards:
		var p := _center(_visual.get(g.id, Vector2(g.pos)))
		var col: Color = Palette.GUARD[g.state]
		draw_circle(p, TILE * 0.32, col.darkened(0.55))
		draw_arc(p, TILE * 0.32, 0, TAU, 32, col, 3.0)
		var f := Vector2(g.facing)
		var side := Vector2(-f.y, f.x)
		draw_colored_polygon(PackedVector2Array([
			p + f * TILE * 0.30, p + side * 7 + f * 4, p - side * 7 + f * 4,
		]), col)
		var icon: String = ["", "?", "!"][g.state]
		if icon != "":
			_text(p + Vector2(-TILE * 0.5, -TILE * 0.40), icon, 22, col)


func _draw_player() -> void:
	var p := _center(_visual.get("player", Vector2(state.player_pos)))
	var s := TILE * 0.30
	var col := Palette.DANGER if state.status == GameState.Status.CAUGHT else Palette.PLAYER
	draw_colored_polygon(PackedVector2Array([p + Vector2(0, -s), p + Vector2(s, 0), p + Vector2(0, s), p + Vector2(-s, 0)]), col)
	draw_circle(p, s * 0.35, Palette.PLAYER_CORE)


func _draw_debug() -> void:
	for y in state.grid.height:
		for x in state.grid.width:
			var c := Vector2i(x, y)
			if not state.grid.is_wall(c):
				draw_string(_font, Vector2(c) * TILE + Vector2(3, 11), "%d,%d" % [x, y], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Palette.TEXT_DIM)
	for c in state.noise_cells:
		draw_rect(_rect(c, 18), Color(1, 1, 1, 0.25))
	for g in state.guards:
		var col: Color = Palette.GUARD[g.state]
		for i in g.route.size():
			draw_circle(_center(Vector2(g.route[i])), 4, col.darkened(0.3))
			var nxt := g.route[(i + 1) % g.route.size()]
			draw_dashed_line(_center(Vector2(g.route[i])), _center(Vector2(nxt)), col.darkened(0.5), 1.0, 4.0)
		if g.state != GuardData.State.PATROL:
			draw_line(_center(Vector2(g.pos)), _center(Vector2(g.target)), col, 2.0)
			draw_rect(_rect(g.target, 14), col, false, 2.0)


func _text(pos: Vector2, text: String, size: int, col: Color) -> void:
	draw_string(_font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, TILE, size, col)
