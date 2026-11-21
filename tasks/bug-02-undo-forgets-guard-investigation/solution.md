# Reference solution: bug-02

## Root cause

Undo is implemented with snapshots: `TurnProcessor.submit()` pushes `state.clone()` before
every turn, and `undo()` pops it back. `GameState.clone()` delegates to `GuardData.clone()`
for each guard.

On this branch, `GuardData.clone()` copies the fields you can **see** (position, facing,
state, route) but not the guard's **memory**:

- `target`: where a SUSPICIOUS guard is going, or the last known player position when ALERTED
- `timer`: look-around turns left
- `lost_sight`: turns without seeing the player

So after an undo, a fresh `GuardData` supplies its defaults: `target = (0,0)`, `timer = 0`.
On the next turn `GuardBrain.act()` sees the target (0,0) as unreachable, treats it as
"arrived", rotates once, sees `timer <= 0` and goes back to PATROL.

The guard *looks* right after the undo (same tile, same `?` icon), which is why this needs
the debug overlay or the trace tool to diagnose.

## Fix

```diff
 func clone() -> GuardData:
 	var g := GuardData.new()
 	g.id = id
 	g.pos = pos
 	g.facing = facing
 	g.route = route.duplicate()
 	g.route_index = route_index
 	g.state = state
+	g.target = target
+	g.timer = timer
+	g.lost_sight = lost_sight
 	return g
```

Diff between the branches: `git diff bug/02-undo-forgets-guard-investigation main -- scripts/core/guard_data.gd`

## Hardening (optional, done on main)

- `test_undo_redo_matches_straight_run_on_level_01` compares full `summary()` strings, and
  `GuardData.summary()` includes target, timer and lost_sight. Any field added later that
  clone() forgets will show up as a test failure, as long as it's also added to summary().
- A comment on `GuardData.clone()` points to this task.

## Why not other fixes

| Alternative | Problem |
|-------------|---------|
| Undo by running the inverse of each command | Guards and cameras would need inverse logic for every rule. Snapshots are simpler and exact. |
| Replay the input log from turn 0 on every undo | Correct (the simulation is deterministic), but undo becomes O(turns), and it hides the clone bug instead of fixing it. |
| Reset guards to PATROL on undo | Changes the game rules and fails acceptance A. |

## Verification done

- `DDDRRWWWWWWWRWZW` and `DDDRRWWWWWWWRW` give identical summaries on level 01.
- Test suite: 37 passed, 0 failed. All reference solutions WIN.
