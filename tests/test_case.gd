class_name TestCase
extends RefCounted
## Minimal assertion base class. Every method starting with `test_` in a
## subclass is run by tests/run_tests.gd. No external addon needed, so the
## suite runs in CI with a plain headless Godot binary.

var failures := PackedStringArray()


func assert_true(cond: bool, msg := "") -> void:
	if not cond:
		failures.append("expected true. " + msg)


func assert_false(cond: bool, msg := "") -> void:
	if cond:
		failures.append("expected false. " + msg)


func assert_eq(actual: Variant, expected: Variant, msg := "") -> void:
	if typeof(actual) != typeof(expected) or actual != expected:
		failures.append("expected <%s> but got <%s>. %s" % [str(expected), str(actual), msg])


## Builds an in-memory level so each test documents its own scenario.
func level(rows: Array, extra := {}) -> Dictionary:
	var data := {"name": "test", "map": rows}
	data.merge(extra)
	return data


func state_of(rows: Array, extra := {}) -> GameState:
	return LevelLoader.build_state(level(rows, extra))


func run(rows: Array, extra: Dictionary, inputs: String) -> TurnProcessor:
	return Replay.run(level(rows, extra), inputs)
