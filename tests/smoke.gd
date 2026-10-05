extends SceneTree

func _init() -> void:
	var required := [
		"res://scenes/main.tscn",
		"res://scripts/main.gd",
		"res://scripts/doodle_player.gd",
		"res://scripts/doodle_visual.gd",
		"res://scripts/touch_controls.gd",
		"res://scripts/brick_wall.gd",
		"res://scripts/movable_crate.gd",
		"res://scripts/street_walk.gd",
		"res://scripts/world_activity_manager.gd"
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
	var npc := instance.get_node_or_null("PathNPC2")
	var wall := instance.get_node_or_null("BrickWall")
	var crate := instance.get_node_or_null("MovableCrate")
	var street := instance.get_node_or_null("StreetWalk")
	var manager := instance.get_node_or_null("WorldActivityManager")
	if npc == null or wall == null or crate == null or street == null or manager == null:
		push_error("Living-world laboratory actors were not created")
		quit(1)
		return
	if get_nodes_in_group("npc").size() != 6 or npc.route_points.size() < 8:
		push_error("Routed pedestrian population was not configured")
		quit(1)
		return
	if ProjectSettings.get_setting("display/window/handheld/orientation") != 0:
		push_error("Landscape orientation is not forced")
		quit(1)
		return
	if not player.show_connectors or not npc.show_connectors:
		push_error("Permanent doodle connectors were not enabled")
		quit(1)
		return
	if crate.z_index >= player.z_index:
		push_error("Short crate must render below doodle characters")
		quit(1)
		return
	player.push_target = npc
	if not player.push_nearby_npc() or player.push_animation_time <= 0.0:
		push_error("Contextual NPC push animation did not start")
		quit(1)
		return
	for frame in 13:
		await physics_frame
	if not npc.ragdoll_active:
		push_error("Timed push pose did not deliver the NPC impact")
		quit(1)
		return
	for frame in 13:
		await physics_frame
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
	print("4TH HEAVEN v0.1.1 living world smoke test passed")
	quit(0)
