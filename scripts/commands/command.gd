class_name Command
extends RefCounted
## Base class for player actions (Command pattern).
##
## A command only describes the PLAYER's action. The rest of the turn
## (cameras, guards, detection) is resolved by TurnProcessor, which keeps
## the phase order in a single place.
##
## `code` is a one-letter token so a whole play session can be written as a
## string, e.g. "RRDHW". That string is what tests, the solver and task
## acceptance criteria use as the "input sequence".

var code := "?"


## Invalid commands (walking into a wall, hacking nothing) are rejected
## BEFORE a snapshot is taken, so they never consume a turn.
func can_execute(_state: GameState) -> bool:
	return true


func execute(_state: GameState) -> void:
	pass
