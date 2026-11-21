class_name CommandFactory
extends RefCounted
## Maps one-letter input tokens to commands.
##   U/D/L/R = move   W = wait   H = hack (interact)

const VALID_CODES := "UDLRWH"


static func from_code(token: String) -> Command:
	match token:
		"U":
			return MoveCommand.new(Dir.N, "U")
		"D":
			return MoveCommand.new(Dir.S, "D")
		"L":
			return MoveCommand.new(Dir.W, "L")
		"R":
			return MoveCommand.new(Dir.E, "R")
		"W":
			return WaitCommand.new()
		"H":
			return InteractCommand.new()
	return null
