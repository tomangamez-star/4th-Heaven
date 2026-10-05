extends Node2D

const PlayerScript = preload("res://scripts/doodle_player.gd")
const TerrainScript = preload("res://scripts/soil_terrain.gd")
const ControlsScript = preload("res://scripts/touch_controls.gd")
const WallScript = preload("res://scripts/brick_wall.gd")
const CrateScript = preload("res://scripts/movable_crate.gd")
const StreetWalkScript = preload("res://scripts/street_walk.gd")
const ActivityManagerScript = preload("res://scripts/world_activity_manager.gd")
const RoadScript = preload("res://scripts/road_layer.gd")
const TrafficCarScript = preload("res://scripts/traffic_car.gd")

const NPC_STYLES := [
	[Color("#d76883"), Color("#46202d"), Color("#633823"), Color("#9d6845")],
	[Color("#6d8fd5"), Color("#26334e"), Color("#211b18"), Color("#47372c")],
	[Color("#e1a84b"), Color("#51391d"), Color("#35231c"), Color("#76503a")],
]

func _ready() -> void:
	var terrain = TerrainScript.new()
	terrain.name = "SoilTerrain"
	add_child(terrain)

	var street_walk = StreetWalkScript.new()
	street_walk.name = "StreetWalk"
	add_child(street_walk)

	var road = RoadScript.new()
	road.name = "RoadLayer"
	add_child(road)
	road.configure(street_walk.get_route())

	var player = PlayerScript.new()
	player.name = "DoodlePlayer"
	player.add_to_group("doodles")
	add_child(player)
	player.global_position = Vector2.ZERO

	var camera := Camera2D.new()
	camera.name = "PlayerCamera"
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.0
	camera.zoom = Vector2(1.18, 1.18)
	camera.limit_left = -2850
	camera.limit_right = 2850
	camera.limit_top = -1850
	camera.limit_bottom = 1850
	player.add_child(camera)

	var controls = ControlsScript.new()
	controls.name = "TouchControls"
	controls.layer = 20
	add_child(controls)
	player.controls = controls

	var lane_offsets := [-178.0, 178.0, -194.0]
	for i in NPC_STYLES.size():
		var npc = PlayerScript.new()
		npc.name = "PathNPC%d" % (i + 1)
		npc.is_npc = true
		npc.clothing_color = NPC_STYLES[i][0]
		npc.clothing_dark = NPC_STYLES[i][1]
		npc.hair_color = NPC_STYLES[i][2]
		npc.hair_highlight = NPC_STYLES[i][3]
		npc.add_to_group("doodles")
		npc.add_to_group("npc")
		add_child(npc)
		var pedestrian_route: PackedVector2Array = street_walk.get_pedestrian_route(lane_offsets[i])
		npc.configure_route(pedestrian_route, i * 3, 0.48 + float(i) * 0.065, i == 1)

	var car = TrafficCarScript.new()
	car.name = "TrafficCar"
	add_child(car)
	car.configure(road.get_vehicle_route(-62.0), 1)

	var activity_manager = ActivityManagerScript.new()
	activity_manager.name = "WorldActivityManager"
	activity_manager.player = player
	add_child(activity_manager)

	var wall = WallScript.new()
	wall.name = "BrickWall"
	add_child(wall)
	wall.global_position = Vector2(250, -265)

	var crate = CrateScript.new()
	crate.name = "MovableCrate"
	add_child(crate)
	crate.global_position = Vector2(180, 185)
