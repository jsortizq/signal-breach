# Reference solution: feature-01

> Status: **design notes only, implementation pending** (branch `feature/01-noise-decoy`).

## Plan (touch points)

| System | Change |
|--------|--------|
| `GameState` | `decoys_left: int`, `last_move_dir: Vector2i` (default E); copied in `clone()`; `dec=` in `summary()` |
| `LevelLoader` | read `"decoys"` (default 0) |
| `MoveCommand` | set `state.last_move_dir` |
| `commands/throw_command.gd` (new) | `can_execute`: decoys > 0 and first tile passable. `execute`: walk up to 3 tiles, append the landing tile to `pending_noise`, decrement, log |
| `CommandFactory` | `"T"` → `ThrowCommand` |
| `project.godot` | input action `throw_decoy` = Q |
| `main.gd` | map `throw_decoy` → `"T"`; better toast messages on rejection |
| `Hud` | "Decoys N" in the stats line |
| `tools/solve.gd` | add `T` to `CODES` |

Undo comes for free: the decoy count and the noise both live in `GameState`, which is
snapshotted before every turn. The noise and guard reactions come for free too, because the
throw reuses `pending_noise` and the turn pipeline doesn't change.

## Edge cases to cover

- First tile blocked → rejected (no turn, no snapshot).
- A guard stops the throw like a wall (it lands in front of the guard).
- The player hasn't moved yet → throw East.
- Undo after a throw restores both the count and the guards.
