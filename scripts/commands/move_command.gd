class_name MoveCommand
extends Command

var dir := Vector2i.ZERO


func _init(direction: Vector2i, token: String) -> void:
	dir = direction
	code = token


func can_execute(state: GameState) -> bool:
	return state.is_walkable_for_player(state.player_pos + dir)


func execute(state: GameState) -> void:
	state.player_pos += dir
	if state.grid.is_noisy(state.player_pos):
		state.pending_noise.append(state.player_pos)
		state.log_event("Player stepped on a noisy tile at (%d,%d)" % [state.player_pos.x, state.player_pos.y])
