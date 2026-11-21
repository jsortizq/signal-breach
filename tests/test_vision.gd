extends TestCase


func test_cone_includes_front_and_diagonals() -> void:
	var o := Vector2i(5, 5)
	assert_true(Vision.in_cone(o, Dir.E, Vector2i(6, 5), 4), "straight ahead")
	assert_true(Vision.in_cone(o, Dir.E, Vector2i(6, 6), 4), "45-degree diagonal")
	assert_true(Vision.in_cone(o, Dir.E, Vector2i(9, 5), 4), "at max range")


func test_cone_excludes_sides_back_and_far() -> void:
	var o := Vector2i(5, 5)
	assert_false(Vision.in_cone(o, Dir.E, Vector2i(6, 7), 4), "too wide")
	assert_false(Vision.in_cone(o, Dir.E, Vector2i(4, 5), 4), "behind")
	assert_false(Vision.in_cone(o, Dir.E, Vector2i(5, 6), 4), "pure side")
	assert_false(Vision.in_cone(o, Dir.E, Vector2i(10, 5), 4), "beyond range")
	assert_false(Vision.in_cone(o, Dir.E, o, 4), "own tile")


func test_wall_blocks_line_of_sight() -> void:
	var s := state_of([
		"#######",
		"#..#..#",
		"#######",
	])
	assert_false(Vision.has_line_of_sight(s, Vector2i(1, 1), Vector2i(5, 1)))
	assert_true(Vision.has_line_of_sight(s, Vector2i(1, 1), Vector2i(2, 1)))


func test_diagonal_corner_gap_blocks_sight() -> void:
	# Viewer at (2,2). Walls at (3,2) and (2,3) form a corner; the diagonal
	# cell (3,3) must NOT be visible through the gap.
	var s := state_of([
		"#######",
		"#.....#",
		"#..#..#",
		"#.#...#",
		"#.....#",
		"#######",
	])
	assert_false(Vision.can_see(s, Vector2i(2, 2), Dir.E, 4, Vector2i(3, 3)), "corner gap (3,3)")
	assert_false(Vision.can_see(s, Vector2i(2, 2), Dir.E, 4, Vector2i(4, 4)), "behind corner (4,4)")


func test_closed_door_blocks_open_door_does_not() -> void:
	var s := state_of(["#######", "#..D..#", "#######"], {"doors": [{"id": "d1", "pos": [3, 1]}]})
	assert_false(Vision.can_see(s, Vector2i(1, 1), Dir.E, 4, Vector2i(5, 1)), "door closed")
	s.doors["d1"]["open"] = true
	assert_true(Vision.can_see(s, Vector2i(1, 1), Dir.E, 4, Vector2i(5, 1)), "door open")


func test_viewer_inside_wall_can_see_out() -> void:
	# Cameras are mounted on wall tiles; their own tile must not occlude.
	var s := state_of(["#####", "#...#", "#...#", "##.##"])
	assert_true(Vision.can_see(s, Vector2i(2, 3), Dir.N, 3, Vector2i(2, 1)))


func test_bresenham_endpoints_and_order() -> void:
	var line := Vision.line_cells(Vector2i(0, 0), Vector2i(3, 1))
	assert_eq(line[0], Vector2i(0, 0))
	assert_eq(line[line.size() - 1], Vector2i(3, 1))
	assert_eq(line.size(), 4)


func test_shelf_corner_hides_player_in_level_02() -> void:
	# Level 02 (Archives): after "LLLL" the player stands at (6,1), behind
	# the diagonal shelf. When g1 perceives on turn 4 it is at (3,4) facing E;
	# the line to the player squeezes between shelf tiles (5,3) and (4,2),
	# so g1 must NOT notice.
	var tp := Replay.run(LevelLoader.load_file("res://levels/level_02.json"), "LLLL")
	assert_eq(tp.state.player_pos, Vector2i(6, 1))
	assert_eq(tp.state.guards[0].state, GuardData.State.PATROL, tp.state.summary())
