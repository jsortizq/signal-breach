# Bug report: after Undo, a suspicious guard forgets what it was doing

**Reported by:** level designer
**Build:** branch `bug/02-undo-forgets-guard-investigation`
**Severity:** high (Undo is a core mechanic; players use it to plan around guards)

> "I'm tuning the Lobby noise lure. I step on the grating, the patrol hears it and
> comes over with a '?'. I take one more step, think better of it and press Z.
> Everything snaps back like it should, the guard is back where it was and still
> shows '?'. But as soon as I press Space, it does a little spin in place and goes
> back to its patrol. If I DON'T undo, it keeps walking toward the noise. So Undo
> changes what happens next. Same position, same icon, different behaviour."

## Steps to reproduce

1. Start level **01 - Lobby**.
2. Enter `DDDRRWWWWWWWR` (D = Down, R = Right, W = Space). On the last step you land on the
   grating at (4,4), and guard g1 turns **"?"**.
3. Press **Space** once: g1 takes a step toward the noise.
4. Press **Z** (undo), then **Space** again.

## Expected

Step 4 ends in exactly the same state as step 3: g1 one tile closer to the noise, still
SUSPICIOUS and facing West.

## Actual

After the undo, g1 spins clockwise and goes back to PATROL within a turn or two, ignoring
the noise. In the debug overlay (F1), g1's target shows `t(0,0)` and its timer shows `tm0`
right after the undo.

## Constraints

- Undo must keep working after being caught and after a restart.
- No change to guard behaviour when Undo isn't used.
