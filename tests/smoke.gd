extends SceneTree

func _init() -> void:
	var required := [
		"res://scenes/main.tscn",
		"res://scripts/main.gd",
		"res://scripts/doodle_player.gd",
		"res://scripts/doodle_visual.gd",
		"res://scripts/touch_controls.gd",
		"res://scripts/brick_wall.gd",
		"res://scripts/movable_crate.gd"
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
	var npc := instance.get_node_or_null("TestNPC")
	var wall := instance.get_node_or_null("BrickWall")
	var crate := instance.get_node_or_null("MovableCrate")
	if npc == null or wall == null or crate == null:
		push_error("Impact laboratory actors were not created")
		quit(1)
		return
	player.set_connectors_enabled(true)
	npc.set_connectors_enabled(true)
	if not player.show_connectors or not npc.show_connectors:
		push_error("Connector comparison could not be enabled")
		quit(1)
		return
	player.push_target = npc
	if not player.push_nearby_npc() or not npc.ragdoll_active:
		push_error("Contextual NPC push did not start the ragdoll")
		quit(1)
		return
	player.trigger_ragdoll(Vector2(390, 0))
	if not player.ragdoll_active or player.rag_positions.size() != 6:
		push_error("Ragdoll did not initialise all six procedural body parts")
		quit(1)
		return
	for frame in 190:
		await physics_frame
	if player.ragdoll_active:
		push_error("Ragdoll did not recover into controlled movement")
		quit(1)
		return
	print("4TH HEAVEN v0.0.3 impact laboratory smoke test passed")
	quit(0)
