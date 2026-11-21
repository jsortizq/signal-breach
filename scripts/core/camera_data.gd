class_name CameraData
extends RefCounted
## Security camera mounted on a wall tile. Rotates through `facings`
## every `period` turns. Can be disabled by hacking a linked terminal.

var id := ""
var pos := Vector2i.ZERO
var facings: Array[Vector2i] = []
var facing_index := 0
var period := 2
var view_range := 5
var enabled := true


func facing() -> Vector2i:
	return facings[facing_index]


func clone() -> CameraData:
	var c := CameraData.new()
	c.id = id
	c.pos = pos
	c.facings = facings.duplicate()
	c.facing_index = facing_index
	c.period = period
	c.view_range = view_range
	c.enabled = enabled
	return c


func summary() -> String:
	return "%s:%s>%s" % [id, "on" if enabled else "off", Dir.to_name(facing())]
