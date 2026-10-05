extends SceneTree

func _init() -> void:
	var required := [
		"res://scenes/main.tscn",
		"res://scripts/main.gd",
		"res://scripts/doodle_player.gd",
		"res://scripts/doodle_visual.gd",
		"res://scripts/touch_controls.gd"
	]
	for path in required:
		if not ResourceLoader.exists(path):
			push_error("Missing required resource: " + path)
			quit(1)
			return
	var scene := load("res://scenes/main.tscn") as PackedScene
	if scene == null:
		push_error("Main scene failed to load")
		quit(1)
		return
	var instance := scene.instantiate()
	root.add_child(instance)
	await process_frame
	var player := instance.get_node_or_null("DoodlePlayer")
	if player == null:
		push_error("DoodlePlayer was not created")
		quit(1)
		return
	print("4TH HEAVEN v0.0.1 smoke test passed")
	quit(0)

