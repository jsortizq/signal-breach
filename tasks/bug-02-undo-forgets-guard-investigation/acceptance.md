# Acceptance criteria: bug-02

Input token `Z` = undo (supported by `Replay.run` and `tools/trace.gd`).

## A. Undo/redo equals a straight run (must change)

| | |
|---|---|
| Level | `res://levels/level_01.json` |
| Straight run | `DDDRRWWWWWWWRW` |
| With undo | `DDDRRWWWWWWWRWZW` |
| Expected | Both end with an identical `GameState.summary()`, including `g1:SUSPICIOUS@(6,4)>W r2 t(4,4) tm2 ls0` |
| Expected visual | g1 one tile right of the gap with an orange `?` and an orange cone pointing West. With F1, an orange line runs from g1 to the noise tile (4,4). |
| Buggy | With the undo, g1 ends `PATROL`, having rotated in place; the debug line to (4,4) is missing |

## B. The snapshot itself (must change)

| | |
|---|---|
| Input | `DDDRRWWWWWWWRWZ` (stop right after the undo) |
| Expected state | g1 summary == `g1:SUSPICIOUS@(7,4)>N r2 t(4,4) tm2 ls0` |
| Buggy state | `g1:SUSPICIOUS@(7,4)>N r2 t(0,0) tm0 ls0` (target and timer lost) |

## C. Regression checks (must NOT change)

| Behaviour | Check |
|-----------|-------|
| Undo after being caught | `test_undo_after_being_caught` |
| Restart clears history | `test_restart_clears_history` |
| Rejected input isn't undoable | `test_rejected_command_is_not_undoable` |
| Snapshots don't share arrays | `test_snapshots_are_independent` |
| Guard behaviour without undo | reference solutions of all levels still WIN |

## D. Automated

```bash
godot --headless --path . --script res://tests/run_tests.gd
```

Must report **0 failed**. Before the fix it fails `test_undo_restores_guard_memory` and
`test_undo_redo_matches_straight_run_on_level_01`.
