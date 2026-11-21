# Tasks

Self-contained challenges built on top of Signal Breach, written in the format of
AI-evaluation tasks: a brief written in the voice of a player, designer or producer,
a reproducible input sequence, a reference solution and verifiable success criteria.

| Task | Type | Systems involved | Branch with the problem |
|------|------|------------------|-------------------------|
| [bug-01](bug-01-vision-through-shelf-corners/) | Bug fix | Vision, guard FSM, level geometry | `bug/01-vision-through-shelf-corners` |
| [bug-02](bug-02-undo-forgets-guard-investigation/) | Bug fix | Undo (snapshots), guard FSM, noise | `bug/02-undo-forgets-guard-investigation` |
| [feature-01](feature-01-noise-decoy/) | Feature | Commands, noise, guard FSM, undo, HUD, input | `main` |

## Folder layout

```
<task>/
  brief.md        what the solver receives (no hints about the cause)
  acceptance.md   input sequences, expected visuals, verifiable states, automated checks
  solution.md     root cause + reference fix (hidden from the solver)
```

## How to reproduce any task

```bash
git checkout <branch>
godot --headless --path . --import
# Watch it turn by turn (Z = undo):
godot --headless --path . --script res://tools/trace.gd -- res://levels/<level>.json <inputs> --board
# Or play it: F1 shows the guard table, F2 copies the input log.
```

## Authoring checklist (applied to every task)

- [x] Reproducible from a fixed input sequence (the simulation is deterministic).
- [x] Visible on screen, not only in logs (vision cones, guard icons, HUD status).
- [x] The brief describes symptoms, never the cause.
- [x] Success is checked by game state (`GameState.summary()`), not by matching code.
- [x] The reference solution passes the whole test suite and every level stays solvable.
- [x] Played end to end on the bugged branch and on the fixed branch.
