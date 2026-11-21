class_name Replay
extends RefCounted
## Runs an input sequence ("RRDHW...") against a level, headless.
## Tokens: U D L R (move), W (wait), H (hack), Z (undo). Spaces are ignored.
## The backbone of tests, the solver and task acceptance criteria:
## same level + same input string = same final state, always.


static func run(level_data: Dictionary, inputs: String) -> TurnProcessor:
	var tp := TurnProcessor.new(LevelLoader.build_state(level_data))
	for token in inputs:
		if token == " ":
			continue
		if token == "Z":
			tp.undo()
			continue
		tp.submit(CommandFactory.from_code(token))
	return tp
