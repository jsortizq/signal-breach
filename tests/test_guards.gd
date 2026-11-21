extends TestCase


func test_noise_makes_guard_suspicious() -> void:
	var tp := run(["########", "#P~...G#", "########"], {"guards": [{"id": "g1", "pos": [6, 1], "facing": "E"}]}, "R")
	var g := tp.state.guards[0]
	assert_eq(g.state, GuardData.State.SUSPICIOUS)
	assert_eq(g.target, Vector2i(2, 1), "investigates the noise source")


func test_noise_does_not_pass_through_walls() -> void:
	# (2,1) and (4,1) are 2 tiles apart, but there is no open path between them.
	var tp := run(["#######", "#P~#G.#", "#..#..#", "#######"], {"guards": [{"id": "g1", "pos": [4, 1], "facing": "E"}]}, "R")
	assert_eq(tp.state.guards[0].state, GuardData.State.PATROL)


func test_noise_blocked_by_closed_door() -> void:
	var extra := {"doors": [{"id": "d1", "pos": [3, 1]}], "guards": [{"id": "g1", "pos": [5, 1], "facing": "E"}]}
	var tp := run(["#######", "#P~D.G#", "#######"], extra, "R")
	assert_eq(tp.state.guards[0].state, GuardData.State.PATROL)


func test_far_sighting_is_suspicious_close_is_alerted() -> void:
	var far := run(["########", "#P....G#", "########"], {"guards": [{"id": "g1", "pos": [6, 1], "facing": "W"}]}, "R")
	assert_eq(far.state.guards[0].state, GuardData.State.SUSPICIOUS, "distance 4")
	var close := run(["######", "#P..G#", "######"], {"guards": [{"id": "g1", "pos": [4, 1], "facing": "W"}]}, "R")
	assert_eq(close.state.guards[0].state, GuardData.State.ALERTED, "distance 2")


func test_alerted_guard_catches_adjacent_player() -> void:
	var tp := run(["#######", "#P.G..#", "#######"], {"guards": [{"id": "g1", "pos": [3, 1], "facing": "W"}]}, "W")
	assert_eq(tp.state.guards[0].state, GuardData.State.ALERTED)
	assert_eq(tp.state.status, GameState.Status.PLAYING, "one tile away after stepping")
	tp.submit(CommandFactory.from_code("W"))
	assert_eq(tp.state.status, GameState.Status.CAUGHT)


func test_suspicious_guard_searches_then_resumes_patrol() -> void:
	var s := state_of(["#######", "#P#..G#", "#######"], {"guards": [{"id": "g1", "pos": [5, 1], "facing": "E", "route": [[5, 1], [4, 1]]}]})
	var g := s.guards[0]
	g.state = GuardData.State.SUSPICIOUS
	g.target = g.pos
	g.timer = GuardBrain.SEARCH_TURNS
	var tp := TurnProcessor.new(s)
	tp.submit(CommandFactory.from_code("W"))
	assert_eq(tp.state.guards[0].state, GuardData.State.SUSPICIOUS, "first look-around turn")
	tp.submit(CommandFactory.from_code("W"))
	assert_eq(tp.state.guards[0].state, GuardData.State.PATROL, "search finished")


func test_alerted_guard_gives_up_after_losing_sight() -> void:
	var s := state_of(["########", "#P#....#", "########"], {"guards": [{"id": "g1", "pos": [6, 1], "facing": "E"}]})
	var g := s.guards[0]
	g.state = GuardData.State.ALERTED
	g.target = Vector2i(6, 1)
	var tp := TurnProcessor.new(s)
	for i in GuardBrain.LOSE_SIGHT_TURNS:
		tp.submit(CommandFactory.from_code("W"))
	assert_eq(tp.state.guards[0].state, GuardData.State.SUSPICIOUS)


func test_camera_alarm_alerts_every_guard() -> void:
	var extra := {
		"cameras": [{"id": "c1", "pos": [4, 2], "facings": ["N"], "period": 0, "range": 3}],
		"guards": [{"id": "g1", "pos": [7, 1], "facing": "E"}],
	}
	var tp := run(["#########", "#P......#", "####.####", "#########"], extra, "RR")
	assert_true(tp.state.camera_alert)
	assert_eq(tp.state.guards[0].state, GuardData.State.ALERTED)
	assert_eq(tp.state.guards[0].target, Vector2i(3, 1))


func test_hacked_terminal_disables_camera() -> void:
	var extra := {
		"cameras": [{"id": "c1", "pos": [4, 2], "facings": ["N"], "period": 0, "range": 3}],
		"terminals": [{"id": "t1", "pos": [1, 2], "targets": ["c1"]}],
		"guards": [{"id": "g1", "pos": [7, 1], "facing": "E"}],
	}
	var tp := run(["#########", "#P......#", "#T##.####", "#########"], extra, "HRR")
	assert_false(tp.state.cameras[0].enabled)
	assert_false(tp.state.camera_alert)
	assert_eq(tp.state.guards[0].state, GuardData.State.PATROL)


func test_camera_rotates_on_its_period() -> void:
	var extra := {"cameras": [{"id": "c1", "pos": [3, 0], "facings": ["S", "E"], "period": 2, "range": 3}]}
	var tp := run(["#######", "#P....#", "#######"], extra, "W")
	assert_eq(tp.state.cameras[0].facing(), Dir.S, "turn 1")
	tp.submit(CommandFactory.from_code("W"))
	assert_eq(tp.state.cameras[0].facing(), Dir.E, "turn 2")


func test_patrol_follows_route_in_loop() -> void:
	var extra := {"guards": [{"id": "g1", "pos": [3, 1], "facing": "E", "route": [[5, 1], [3, 1]]}]}
	var tp := run(["#########", "#P#.....#", "#########"], extra, "WWWW")
	assert_eq(tp.state.guards[0].pos, Vector2i(3, 1), "went to (5,1) and back")
