# Bug report: guards see through the shelves in the Archives

**Reported by:** playtester (Discord, #bug-reports)
**Build:** branch `bug/01-vision-through-shelf-corners`
**Severity:** high (makes level 02 unfair; breaks trust in the stealth rules)

> "On Archives I went along the top of the room, staying on the far side of the
> diagonal shelves like the briefing says. The guard on the left still clocked me
> straight away, from behind the shelf. Then I turned on the debug view and the
> yellow vision cone is literally poking through the gaps between the shelves.
> Pretty sure that isn't supposed to happen? Walls everywhere else seem fine."

## Steps to reproduce

1. Start level **02 - Archives** (from level 1 press F1, then Enter).
2. Press **Left** 4 times (input log `LLLL`).
3. Look at guard **g1** (left side of the room) and its cone.

## Expected

The shelves block sight completely. No cone tiles show up on the upper-right side of the
shelf line, and g1 stays in **PATROL**.

## Actual

g1's cone shows tiles behind the shelves, through the diagonal gaps. g1 shows **"?"**
(SUSPICIOUS) and walks toward the player. Keep going with the level's reference route and it
becomes ALERTED and catches the player.

## Constraints

- Fix it in the game logic, not by editing the level.
- Don't break any other vision behaviour (cameras on walls, doors, cone shape).
