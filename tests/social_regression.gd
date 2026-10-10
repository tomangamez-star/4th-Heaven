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
	var first: String = npc.personality.greet(player)
	var second: String = npc.personality.greet(player)
	check(first != second, "Repeat greeting did not recognize player")
	npc.personality.mood = "upset"
	check(npc.personality.greet(player) == "Give me a moment!", "Upset NPC ignored mood")
	player.personality.emote("wave")
	check(player.personality.gesture == "wave", "Wave failed")
	check(market.get_node_or_null("ShopWall0") != null and market.get_node_or_null("ShopWall1") != null, "Buildings have no boundaries")
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
	if failed:
		quit(1)
		return
	print("v0.2.8 social regressions passed: head bounds, raster layers, moods, buildings, shop visits, seating")
	quit(0)
