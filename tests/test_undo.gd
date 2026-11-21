extends TestCase

const NOISE_LEVEL := ["########", "#P~...G#", "########"]
const NOISE_EXTRA := {
	"guards": [{"id": "g1", "pos": [6, 1], "facing": "E"}],
	"terminals": [],
}


func test_undo_restores_previous_summary() -> void:
	var tp := run(NOISE_LEVEL, NOISE_EXTRA, "")
	var before := tp.state.summary()
	tp.submit(CommandFactory.from_code("R")) # noisy tile -> guard SUSPICIOUS
	assert_eq(tp.state.guards[0].state, GuardData.State.SUSPICIOUS, "precondition")
	assert_true(tp.undo())
	assert_eq(tp.state.summary(), before)


func test_undo_restores_guard_memory() -> void:
	# The guard's investigation target and search timer are part of the
	# state. If clone() forgets them, undo + redo diverges from a clean run.
	var straight := run(NOISE_LEVEL, NOISE_EXTRA, "RWW")
	var tp := run(NOISE_LEVEL, NOISE_EXTRA, "RWW")
	tp.undo()
	tp.undo()
	tp.submit(CommandFactory.from_code("W"))
	tp.submit(CommandFactory.from_code("W"))
	assert_eq(tp.state.summary(), straight.state.summary())


func test_undo_after_being_caught() -> void:
	var tp := run(["######", "#PG..#", "######"], {"guards": [{"id": "g1", "pos": [2, 1], "facing": "W"}]}, "W")
	assert_eq(tp.state.status, GameState.Status.CAUGHT, tp.state.summary())
	assert_true(tp.undo())
	assert_eq(tp.state.status, GameState.Status.PLAYING)
	assert_eq(tp.state.turn, 0)


func test_rejected_command_is_not_undoable() -> void:
	var tp := run(NOISE_LEVEL, NOISE_EXTRA, "U")
	assert_false(tp.can_undo())
	assert_false(tp.undo())


func test_restart_clears_history() -> void:
	var tp := run(NOISE_LEVEL, NOISE_EXTRA, "RW")
	tp.restart()
	assert_eq(tp.state.turn, 0)
	assert_false(tp.can_undo())
	assert_eq(tp.replay_string(), "")


func test_snapshots_are_independent() -> void:
	var s := state_of(NOISE_LEVEL, NOISE_EXTRA)
	var copy := s.clone()
	copy.guards[0].pos = Vector2i(2, 1)
	copy.guards[0].route.append(Vector2i(3, 1))
	assert_eq(s.guards[0].pos, Vector2i(6, 1), "guard position leaked into original")
	assert_eq(s.guards[0].route.size(), 0, "route array is shared")


func test_replay_is_deterministic() -> void:
	var data := LevelLoader.load_file("res://levels/level_03.json")
	var inputs := "DRRDDDDRRDDRWRRRRRRR"
	assert_eq(Replay.run(data, inputs).state.summary(), Replay.run(data, inputs).state.summary())


func test_undo_redo_matches_straight_run_on_level_01() -> void:
	# Guard g1 is SUSPICIOUS (investigating a noise) when the undo happens.
	var data := LevelLoader.load_file("res://levels/level_01.json")
	var straight := Replay.run(data, "DDDRRWWWWWWWRW")
	var with_undo := Replay.run(data, "DDDRRWWWWWWWRWZW")
	assert_eq(with_undo.state.summary(), straight.state.summary())
