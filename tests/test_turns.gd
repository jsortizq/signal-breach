extends TestCase

const CORRIDOR := ["#######", "#P...E#", "#######"]
const ONE_OBJECTIVE := {"terminals": [{"id": "t1", "pos": [3, 2], "objective": true}]}


func test_invalid_move_consumes_no_turn() -> void:
	var tp := run(CORRIDOR, {}, "U")
	assert_eq(tp.state.turn, 0)
	assert_eq(tp.state.player_pos, Vector2i(1, 1))
	assert_eq(tp.replay_string(), "", "rejected input must not be logged")


func test_valid_move_advances_turn() -> void:
	var tp := run(CORRIDOR, {}, "RR")
	assert_eq(tp.state.turn, 2)
	assert_eq(tp.state.player_pos, Vector2i(3, 1))


func test_player_acts_before_guards_perceive() -> void:
	# Guard at (3,1) faces S. Player at (2,2) is inside the cone; stepping
	# left to (1,2) leaves it. Guards perceive AFTER the player moves, so
	# the escape must succeed.
	var tp := run(
		["#####", "#...#", "#.P.#", "#####"],
		{"guards": [{"id": "g1", "pos": [3, 1], "facing": "S"}]},
		"L"
	)
	assert_eq(tp.state.guards[0].state, GuardData.State.PATROL, tp.state.summary())


func test_hack_requires_adjacent_terminal() -> void:
	var extra := {"terminals": [{"id": "t1", "pos": [4, 1], "objective": true}]}
	var far := run(["#######", "#P...E#", "#######"], extra, "H")
	assert_eq(far.state.turn, 0, "H with no adjacent terminal is rejected")
	var near := run(["#######", "#P...E#", "#######"], extra, "RRH")
	assert_true(near.state.terminals["t1"]["hacked"])


func test_hack_opens_linked_door() -> void:
	var tp := run(
		["#######", "#P.D.E#", "#.T####", "#######"],
		{"doors": [{"id": "d1", "pos": [3, 1]}],
		 "terminals": [{"id": "t1", "pos": [2, 2], "targets": ["d1"]}, {"id": "t2", "pos": [4, 2], "objective": true}]},
		"RH"
	)
	assert_true(tp.state.doors["d1"]["open"])


func test_exit_locked_until_objectives_hacked() -> void:
	var rows := ["#######", "#P...E#", "###.###", "#######"]
	var extra := {"terminals": [{"id": "t1", "pos": [3, 2], "objective": true}]}
	var locked := run(rows, extra, "RRRR")
	assert_eq(locked.state.status, GameState.Status.PLAYING, "exit reached without hacking")
	var won := run(rows, extra, "RRHRR")
	assert_eq(won.state.status, GameState.Status.WON)


func test_no_input_accepted_after_game_over() -> void:
	var rows := ["#######", "#P...E#", "###.###", "#######"]
	var tp := run(rows, ONE_OBJECTIVE, "RRHRR")
	assert_false(tp.submit(CommandFactory.from_code("L")))
