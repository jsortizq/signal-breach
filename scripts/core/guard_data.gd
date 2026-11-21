class_name GuardData
extends RefCounted
## Plain data for one guard. Behaviour lives in GuardBrain (scripts/ai).

enum State { PATROL, SUSPICIOUS, ALERTED }
const STATE_NAMES: Array[String] = ["PATROL", "SUSPICIOUS", "ALERTED"]

var id := ""
var pos := Vector2i.ZERO
var facing := Dir.E
## Looping list of waypoints. Empty route = stationary sentry.
var route: Array[Vector2i] = []
var route_index := 0
var state: int = State.PATROL
## SUSPICIOUS: where to investigate. ALERTED: last known player position.
var target := Vector2i.ZERO
## SUSPICIOUS: look-around turns left once the target is reached.
var timer := 0
## ALERTED: consecutive turns without seeing the player.
var lost_sight := 0


## Deep copy used by the undo snapshots.
func clone() -> GuardData:
	var g := GuardData.new()
	g.id = id
	g.pos = pos
	g.facing = facing
	g.route = route.duplicate()
	g.route_index = route_index
	g.state = state
	return g


func state_name() -> String:
	return STATE_NAMES[state]


func summary() -> String:
	return "%s:%s@(%d,%d)>%s r%d t(%d,%d) tm%d ls%d" % [
		id, state_name(), pos.x, pos.y, Dir.to_name(facing),
		route_index, target.x, target.y, timer, lost_sight,
	]
