extends TestCase
## Every shipped level must be valid AND beatable with its stored
## reference solution. This is the automated half of "end-to-end playtesting".


func _level_paths() -> PackedStringArray:
	var out := PackedStringArray()
	var files := DirAccess.get_files_at("res://levels")
	files.sort()
	for f in files:
		if f.ends_with(".json"):
			out.append("res://levels/" + f)
	return out


func test_levels_exist() -> void:
	assert_true(_level_paths().size() >= 3)


func test_all_levels_validate() -> void:
	for path in _level_paths():
		var errors := LevelLoader.validate(LevelLoader.load_file(path))
		assert_true(errors.is_empty(), "%s: %s" % [path, ", ".join(errors)])


func test_reference_solutions_win() -> void:
	for path in _level_paths():
		var data := LevelLoader.load_file(path)
		var solution: String = data.get("reference_solution", "")
		assert_true(solution != "", "%s has no reference_solution" % path)
		var tp := Replay.run(data, solution)
		assert_eq(tp.state.status, GameState.Status.WON, "%s -> %s" % [path, tp.state.summary()])
		assert_eq(tp.replay_string(), solution, "%s: some inputs were rejected" % path)
