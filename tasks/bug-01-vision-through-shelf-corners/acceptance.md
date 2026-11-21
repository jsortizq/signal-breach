# Acceptance criteria: bug-01

## A. Reproduction case (must change)

| | |
|---|---|
| Level | `res://levels/level_02.json` (02 - Archives) |
| Input | `LLLL` |
| Expected visual | No cone tile on the upper-right side of the shelf line `(4,2) (5,3) (6,4) (7,5)`; in particular `(5,2)` and `(6,1)` are not tinted. g1 shows no `?` / `!` icon. HUD says **Undetected**. |
| Expected state | `player_pos == (6,1)`, `guards[0].state == PATROL`, `status == PLAYING` |
| Buggy state | `g1:SUSPICIOUS ... t(6,1)` with the event `g1: PATROL -> SUSPICIOUS (glimpsed player at (6,1))` |

## B. Full level (must change)

| | |
|---|---|
| Input | the level's `reference_solution`: `LLLLLLLDDDDLUUHDDRRRWDDRRRRRR` |
| Expected | `status == WON` after the last input, and no guard ever leaves PATROL |
| Buggy | g1 goes ALERTED on turn 6 and the run ends `CAUGHT` |

## C. Regression checks (must NOT change)

| Behaviour | Check |
|-----------|-------|
| A camera mounted on a wall still sees out | `test_viewer_inside_wall_can_see_out` |
| A closed door blocks sight, an open one doesn't | `test_closed_door_blocks_open_door_does_not` |
| Cone shape: 90°, diagonals included, range 4 | `test_cone_*` |
| A diagonal that passes ONE wall corner (not two) stays visible | in level 04, `(13,2)` is visible from camera `c1` facing N |
| Every level is still solvable | `tools/solve.gd` finds a solution for every level |

## D. Automated

```bash
godot --headless --path . --script res://tests/run_tests.gd
```

Must report **0 failed**. Before the fix it fails `test_diagonal_corner_gap_blocks_sight`,
`test_shelf_corner_hides_player_in_level_02` and `test_reference_solutions_win`.
