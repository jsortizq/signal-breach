class_name LevelLoader
extends RefCounted
## Loads JSON level files into a GameState and validates them.
##
## Map legend:  #  wall      .  floor     ~  noisy floor
##              P  player    E  exit
##              D, T are visual markers only (plain floor); the real doors and
##              terminals come from the object lists below.
## Doors, terminals, guards and cameras are listed as objects with explicit
## coordinates [x, y], so IDs can be referenced in task briefs.


static func load_file(path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(path)
	var data: Variant = JSON.parse_string(text)
	assert(data is Dictionary, "Invalid level JSON: %s" % path)
	return data


static func build_state(data: Dictionary) -> GameState:
	var rows := PackedStringArray(data["map"])
	var s := GameState.new()
	s.level_name = data.get("name", "Untitled")
	s.grid = LevelGrid.new(rows)
	for y in rows.size():
		for x in rows[y].length():
			match rows[y][x]:
				"P":
					s.player_pos = Vector2i(x, y)
				"E":
					s.exit_pos = Vector2i(x, y)

	for d in data.get("doors", []):
		s.doors[d["id"]] = {"pos": _v(d["pos"]), "open": d.get("open", false)}

	for t in data.get("terminals", []):
		var targets: Array[String] = []
		for id in t.get("targets", []):
			targets.append(str(id))
		s.terminals[t["id"]] = {
			"pos": _v(t["pos"]),
			"targets": targets,
			"objective": t.get("objective", false),
			"hacked": false,
		}

	for gd in data.get("guards", []):
		var g := GuardData.new()
		g.id = gd["id"]
		g.pos = _v(gd["pos"])
		g.facing = Dir.from_name(gd.get("facing", "E"))
		for wp in gd.get("route", []):
			g.route.append(_v(wp))
		s.guards.append(g)

	for cd in data.get("cameras", []):
		var c := CameraData.new()
		c.id = cd["id"]
		c.pos = _v(cd["pos"])
		for f in cd["facings"]:
			c.facings.append(Dir.from_name(f))
		c.period = int(cd.get("period", 2))
		c.view_range = int(cd.get("range", 5))
		s.cameras.append(c)
	return s


## Returns a list of human-readable problems. Empty list = valid level.
static func validate(data: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	var s := build_state(data)
	var map_text := "".join(PackedStringArray(data["map"]))
	if map_text.count("P") != 1:
		errors.append("Map needs exactly one 'P'")
	if map_text.count("E") != 1:
		errors.append("Map needs exactly one 'E'")
	if s.objectives_total() == 0:
		errors.append("Level has no objective terminal")
	for id in s.doors:
		if s.grid.is_wall(s.doors[id]["pos"]):
			errors.append("Door %s is inside a wall" % id)
	for id in s.terminals:
		var t: Dictionary = s.terminals[id]
		if s.grid.is_wall(t["pos"]):
			errors.append("Terminal %s is inside a wall" % id)
		for target in t["targets"]:
			var cam_ids := s.cameras.map(func(c: CameraData) -> String: return c.id)
			if not s.doors.has(target) and not cam_ids.has(target):
				errors.append("Terminal %s targets unknown id %s" % [id, target])
	for g in s.guards:
		if not s.is_passable(g.pos):
			errors.append("Guard %s starts on a blocked tile" % g.id)
		for wp in g.route:
			if not s.is_passable(wp):
				errors.append("Guard %s waypoint (%d,%d) is blocked" % [g.id, wp.x, wp.y])
	for c in s.cameras:
		if not s.grid.is_wall(c.pos):
			errors.append("Camera %s must be mounted on a wall" % c.id)
		if c.facings.is_empty():
			errors.append("Camera %s has no facings" % c.id)
	return errors


static func _v(arr: Array) -> Vector2i:
	return Vector2i(int(arr[0]), int(arr[1]))
