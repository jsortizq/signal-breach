extends SceneTree
## Headless test runner. Exit code 0 = all green, 1 = failures.
##   godot --headless --path . --script res://tests/run_tests.gd

const SUITES := [
	"res://tests/test_vision.gd",
	"res://tests/test_turns.gd",
	"res://tests/test_undo.gd",
	"res://tests/test_guards.gd",
	"res://tests/test_levels.gd",
]


func _init() -> void:
	var total := 0
	var failed := 0
	for path in SUITES:
		print("\n", path.get_file())
		var suite: TestCase = load(path).new()
		for method in suite.get_method_list():
			var name: String = method["name"]
			if not name.begins_with("test_"):
				continue
			total += 1
			suite.failures.clear()
			suite.call(name)
			if suite.failures.is_empty():
				print("  PASS  ", name)
			else:
				failed += 1
				print("  FAIL  ", name)
				for f in suite.failures:
					print("        - ", f)
	print("\n%d tests, %d passed, %d failed" % [total, total - failed, failed])
	quit(1 if failed > 0 else 0)
