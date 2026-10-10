extends SceneTree
var failed := false

func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)

func _init() -> void:
	call_deferred("run")

func run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await physics_frame
	var player = scene.get_node("DoodlePlayer")
	var social = scene.get_node("SocialInteractions")
	var market = scene.get_node("MarketDistrict")
	var npc = scene.get_node("PathNPC2")
	var personality = player.personality
	player.set_physics_process(false)
	personality.set_physics_process(false)
	personality.attention_target = null
	personality.glance_timer = 1000.0
	personality.head_target = 20.0
	for frame in 240:
		personality._physics_process(1.0 / 60.0)
		check(absf(personality.head_angle) <= personality.MAX_HEAD_ANGLE + 0.001, "Head exceeded bounded sweep")
	var previous: float = personality.head_angle
	personality.head_target = -20.0
	personality._physics_process(1.0 / 60.0)
	check(absf(personality.head_angle - previous) < 0.2, "Head snapped across left/right limit")
	check(load("res://scripts/doodle_atlas.gd").get_part(0).get_width() > 0, "Raster hair missing")
	check(load("res://scripts/doodle_atlas.gd").get_part(8).get_height() > 0, "Raster accessory missing")
	check(load("res://scripts/foliage_atlas.gd").get_part(0).get_width() > 0, "Raster foliage missing")
	var rig_atlas = load("res://scripts/directional_rig_atlas.gd")
	check(rig_atlas.get_part(0).get_width() > 0 and rig_atlas.get_part(15).get_width() > 0, "Eight-direction head/body atlas missing")
	check(player.player_visual_style == 0, "Player style did not begin in Classic")
	check(player.cycle_player_visual_style() == 1 and player.cycle_player_visual_style() == 2 and player.cycle_player_visual_style() == 0, "Player style toggle did not cycle all three modes")
	var first: String = npc.personality.greet(player)
	var second: String = npc.personality.greet(player)
	check(first != second, "Repeat greeting did not recognize player")
	npc.personality.mood = "upset"
	check(npc.personality.greet(player) == "Give me a moment!", "Upset NPC ignored mood")
	player.personality.emote("wave")
	check(player.personality.gesture == "wave", "Wave failed")
	check(market.get_node_or_null("ShopWall0") != null and market.get_node_or_null("ShopWall1") != null, "Buildings have no boundaries")
	check(market.get_node_or_null("ShopSign0") != null and market.get_node_or_null("ShopSign1") != null, "Shops are not visibly signed")
	check(market.get_node_or_null("MarketStreetGateway") != null, "Market route has no visible gateway")
	check(market.get_node_or_null("ShopSilhouetteShadow0") != null, "Shop silhouette shadow missing")
	var roads = scene.get_node("RasterRoads")
	for center in market.CENTERS:
		for offset in [Vector2(-180, -200), Vector2(180, 200), Vector2(-180, 200), Vector2(180, -200)]:
			check(not roads.is_on_road(center + offset), "Building overlaps driving surface")
	var visitor = market.get_node("MarketVisitor0")
	visitor.set_physics_process(false)
	visitor.global_position = visitor.shop_door
	visitor.visit_cooldown = 0.0
	visitor._update_npc(0.016)
	await physics_frame
	check(visitor.inside_time > 0.0 and visitor.get_node("CollisionShape2D").disabled, "Shop visit did not release doorway collision")
	for frame in 300: visitor._update_npc(1.0 / 60.0)
	await physics_frame
	check(visitor.inside_time <= 0.0 and not visitor.get_node("CollisionShape2D").disabled and visitor.visual.modulate.a > 0.9, "Visitor did not return from shop")
	player.is_sitting = true
	social._sit()
	check(not player.is_sitting, "Stand action did not restore walking")
	var furniture = scene.get_node("StreetFurniture")
	for point in furniture.light_directions:
		check(furniture.light_directions[point].length() > 0.99, "Lamp has invalid direction")
		check(not roads.is_on_road(point), "Lamp base placed on a driving surface: " + str(point))
	check(get_nodes_in_group("night_fixture_light").size() == furniture.streetlight_spots.size() + furniture.roadlight_spots.size(), "Visible lamp-head glows do not match fixtures")
	check(get_nodes_in_group("night_fixture_halo").is_empty(), "Opaque lamp halo sprites returned")
	check(get_nodes_in_group("vehicle_world_headlight").size() >= 5, "Vehicle world-surface headlights missing")
	if failed:
		quit(1)
		return
	print("v0.3.0 regressions passed: true directional rig, fitted hair, market gateway, silhouette shadows and surface lights")
	quit(0)
