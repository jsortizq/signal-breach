class_name WaitCommand
extends Command


func _init() -> void:
	code = "W"


func execute(state: GameState) -> void:
	state.log_event("Player waited")
