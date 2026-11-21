# Feature request: noise decoy

**From:** game designer
**Target build:** `main`

> "Players love luring guards with the grating, but you can only do it where the level
> designer put grating. I want a **decoy**: the player throws a noisemaker onto a tile
> and every guard within earshot goes to investigate it. It should feel like a real
> decision, so it's limited, it costs a turn, and it has to play nicely with Undo."

## Requirements

1. **Input:** press **Q** to throw a decoy in the direction the player last moved
   (start of level: East). Input token for replays: `T`.
2. **Range:** it lands on the **farthest passable tile up to 3 tiles away** in that
   direction, stopping before any wall, closed door, terminal or guard.
   If the very first tile is blocked, the throw is rejected and costs no turn.
3. **Effect:** it makes noise at the landing tile exactly like a noisy floor tile:
   same radius, same propagation, same guard reactions.
4. **Limit:** each level grants `"decoys": N` in its JSON (default 0). The HUD shows how
   many are left. With 0 left, the throw is rejected and costs no turn.
5. **Turn cost:** a throw is a full turn: the player doesn't move, then the normal turn
   pipeline runs (cameras, perception, guards).
6. **Undo:** undoing a throw gives the decoy back and restores every guard exactly.
7. **Feedback:** the landing tile shows the existing noise ring, and the event log reads
   `Decoy landed at (x,y)`.

## Out of scope

Throw arcs, animations of the projectile, picking decoys back up.
