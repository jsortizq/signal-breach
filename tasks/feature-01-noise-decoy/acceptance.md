# Acceptance criteria: feature-01

Test level (add as `res://levels/test_decoy.json`, or build it inline in a test):

```
"map": [
  "##########",
  "#P.......#",
  "#........#",
  "#........#",
  "##########"
],
"guards": [{ "id": "g1", "pos": [6, 2], "facing": "S" }],
"decoys": 2
```

| # | Input | Expected state | Expected on screen |
|---|-------|----------------|--------------------|
| 1 | `T` | turn 1; decoy at (4,1); `decoys_left == 1`; g1 `SUSPICIOUS`, target (4,1) | noise ring at (4,1); g1 shows `?`; HUD "Decoys 1" |
| 2 | `TZ` | turn 0; `decoys_left == 2`; g1 `PATROL` | no ring; HUD "Decoys 2" |
| 3 | `TT` | `decoys_left == 0` | HUD "Decoys 0" |
| 4 | `TTT` | third `T` rejected: still turn 2, nothing in the log for it | toast "No decoys left" |
| 5 | `DDRT` (player at (2,3), last move East) | lands on (5,3) | ring at (5,3) |
| 6 | `DDT` (player at (1,3), last move South, wall right below) | `T` rejected, still turn 2 | toast |
| 7 | `RRRRRT` (player at (6,1), facing E) | lands on (8,1): the farthest passable tile, only 2 away | ring at (8,1) |
| 8 | any level with no `"decoys"` key, `T` | rejected | HUD "Decoys 0" |

## Determinism and integration

- `Replay.run(level, "T...")` and in-game play must produce identical `summary()` output.
- `summary()` includes the decoy count, e.g. `dec=1`.
- All existing tests stay green; all existing reference solutions still WIN (levels without decoys are unaffected).
- `tools/solve.gd` explores `T` as a move, so levels with decoys stay provably solvable.

## Automated

Add tests covering rows 1, 2, 4, 6 and 7 to `tests/test_decoy.gd` and register the file in
`tests/run_tests.gd`. Suite must report 0 failed.
