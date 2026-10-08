extends SceneTree

func _init() -> void:
	var required := [
		"res://scenes/main.tscn",
		"res://scripts/main.gd",
		"res://scripts/doodle_player.gd",
		"res://scripts/doodle_visual.gd",
		"res://scripts/touch_controls.gd",
		"res://scripts/street_walk.gd",
		"res://scripts/world_activity_manager.gd",
		"res://scripts/world_light_manager.gd",
		"res://scripts/street_furniture.gd",
		"res://scripts/shelter_roof_overlay.gd",
		"res://scripts/central_plaza.gd",
		"res://scripts/central_pavilion_roof.gd",
		"res://scripts/road_layer.gd",
		"res://scripts/traffic_car.gd"
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
	var street := instance.get_node_or_null("StreetWalk")
	var road := instance.get_node_or_null("RoadLayer")
	var car := instance.get_node_or_null("TrafficCar")
	var manager := instance.get_node_or_null("WorldActivityManager")
	var light := instance.get_node_or_null("WorldLightManager")
	var furniture := instance.get_node_or_null("StreetFurniture")
	var plaza := instance.get_node_or_null("CentralStationPlaza")
	var controls := instance.get_node_or_null("TouchControls")
	if npc == null or street == null or road == null or car == null or manager == null or light == null or furniture == null or plaza == null or controls == null:
		push_error("Living-street actors were not created")
		quit(1)
		return
	if instance.get_node_or_null("BrickWall") != null or instance.get_node_or_null("MovableCrate") != null:
		push_error("Temporary laboratory props still exist in the central loop")
		quit(1)
		return
	if get_nodes_in_group("npc").size() != 6 or npc.route_points.size() < 8:
		push_error("Routed pedestrian population was not configured")
		quit(1)
		return
	if instance.get_node("SoilTerrain").z_index >= street.z_index or street.z_index >= road.z_index:
		push_error("Soil, sidewalk and road rendering order is incorrect")
		quit(1)
		return
	# Regression guard for the blank-opening-screen failure: the road, player,
	# pedestrians and car must all begin inside or just beyond the
	# first landscape camera view.
	var opening_half_view := Vector2(1280, 720) * 0.5 / 1.08
	var opening_margin := Vector2(120, 120)
	var opening_bounds := Rect2(-opening_half_view - opening_margin, (opening_half_view + opening_margin) * 2.0)
	if not opening_bounds.has_point(player.global_position):
		push_error("Player is outside the opening camera")
		quit(1)
		return
	for node in [npc, car]:
		if not opening_bounds.has_point(node.global_position):
			push_error("Opening actor is outside the camera: " + node.name)
			quit(1)
			return
	var route_crosses_opening := false
	for point in road.route:
		if opening_bounds.has_point(point):
			route_crosses_opening = true
			break
	if not route_crosses_opening:
		push_error("Road does not cross the opening camera")
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
	if furniture.get_sit_spots().size() != 6 or furniture.get_gather_spots().size() != 2:
		push_error("Street furniture behaviour destinations were not configured")
		quit(1)
		return
	if furniture.get_prop_count() != 9:
		push_error("Corrected sparse furniture budget was not applied")
		quit(1)
		return
	for point in furniture.bench_spots + furniture.bus_stop_spots + furniture.gather_spots:
		if furniture.is_point_on_road(point):
			push_error("Furniture or social destination was placed on the road")
			quit(1)
			return
	var collisions := furniture.get_node_or_null("FurnitureCollisions")
	var roof := furniture.get_node_or_null("GlassShelterRoof")
	if collisions == null or collisions.get_child_count() < 10 or roof == null or roof.z_index <= player.z_index:
		push_error("Furniture collisions or above-doodle glass roof were not created")
		quit(1)
		return
	if light.get_shadow_offset(10.0).length() < 10.0:
		push_error("Shared world shadow direction was not configured")
		quit(1)
		return
	var plaza_collisions := plaza.get_node_or_null("PlazaCollisions")
	var pavilion_roof := plaza.get_node_or_null("PavilionRoofAndCanopies")
	if plaza_collisions == null or plaza_collisions.get_child_count() != 11 or pavilion_roof == null or pavilion_roof.z_index <= player.z_index:
		push_error("Central plaza layering or collisions were not created")
		quit(1)
		return
	if controls.time_button_centers.size() != 4 or controls.light_manager != light:
		push_error("Four-state lighting test controls were not configured")
		quit(1)
		return
	var afternoon_offset: Vector2 = light.get_shadow_offset(20.0)
	light.set_time_state("night", true)
	if not light.is_night() or light.get_state_index() != 3 or light.get_shadow_offset(20.0).is_equal_approx(afternoon_offset):
		push_error("Night state did not update world lighting and shadow direction")
		quit(1)
		return
	light.set_time_state("afternoon", true)
	var sitter := instance.get_node_or_null("PathNPC4")
	var talker_a := instance.get_node_or_null("PathNPC5")
	var talker_b := instance.get_node_or_null("PathNPC6")
	if not sitter.is_sitting or sitter.behavior_state != "sit" or talker_a.behavior_state != "talk" or talker_b.behavior_state != "talk":
		push_error("Opening sit and talk behaviours were not started")
		quit(1)
		return
	var bubble_sequence := []
	for sample in [0, 340, 680, 1020, 1360]:
		bubble_sequence.append(talker_a.visual.get_talk_dot_count(sample))
	if bubble_sequence != [3, 2, 1, 2, 3]:
		push_error("Conversation bubble dot animation is incorrect")
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
	if car.route.size() < 8:
		push_error("Authored traffic route was not configured")
		quit(1)
		return
	if car.scale.x < 1.2 or road.get_vehicle_route().is_empty():
		push_error("Road and car scale upgrade was not applied")
		quit(1)
		return
	var avoidance_npc := instance.get_node_or_null("PathNPC6")
	avoidance_npc.velocity = Vector2.ZERO
	avoidance_npc.global_position = player.global_position - Vector2(0, 68)
	avoidance_npc.route_points = PackedVector2Array([player.global_position + Vector2(0, 200)])
	avoidance_npc.route_index = 0
	avoidance_npc._update_route_npc(1.0 / 60.0)
	if not avoidance_npc.player_blocked_last_frame or avoidance_npc.velocity.length() > 0.1:
		push_error("Pedestrian did not stop before pushing into the player")
		quit(1)
		return
	print("4TH HEAVEN v0.1.7 central-station lighting smoke test passed")
	quit(0)
