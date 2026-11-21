extends SceneTree
## Renders the main scene after an input sequence and saves a PNG.
## Used to generate README screenshots and visual acceptance evidence.
##   godot --path . --script res://tools/capture.gd -- <level_index> <inputs> <out.png> [debug]
## Needs a real renderer (not --headless); on Linux CI use xvfb-run.


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var level_index := int(args[0]) if args.size() > 0 else 0
	var inputs: String = args[1] if args.size() > 1 else ""
	var out: String = args[2] if args.size() > 2 else "user://capture.png"
	var debug := args.has("debug")

	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main._load_level(level_index)
	for token in inputs:
		main._submit(token)
	if debug:
		main._debug.visible = true
		main._board.show_debug = true
	for i in 40: # let interpolation settle
		await process_frame
	var img := root.get_texture().get_image()
	img.save_png(out)
	print("saved ", out)
	quit()
