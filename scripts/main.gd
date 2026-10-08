extends Node2D

const PlayerScript = preload("res://scripts/doodle_player.gd")
const TerrainScript = preload("res://scripts/soil_terrain.gd")
const ControlsScript = preload("res://scripts/touch_controls.gd")
const StreetWalkScript = preload("res://scripts/street_walk.gd")
const ActivityManagerScript = preload("res://scripts/world_activity_manager.gd")
const RoadScript = preload("res://scripts/road_layer.gd")
const TrafficCarScript = preload("res://scripts/traffic_car.gd")
const WorldLightScript = preload("res://scripts/world_light_manager.gd")
const StreetFurnitureScript = preload("res://scripts/street_furniture.gd")
const CentralPlazaScript = preload("res://scripts/central_plaza.gd")

const NPC_STYLES := [
	[Color("#d76883"), Color("#46202d"), Color("#633823"), Color("#9d6845")],
	[Color("#6d8fd5"), Color("#26334e"), Color("#211b18"), Color("#47372c")],
	[Color("#e1a84b"), Color("#51391d"), Color("#35231c"), Color("#76503a")],
	[Color("#79ad67"), Color("#263c28"), Color("#712f28"), Color("#a95a4d")],
	[Color("#9c76c5"), Color("#38274c"), Color("#d3b06e"), Color("#f0d29a")],
	[Color("#d97755"), Color("#54281e"), Color("#20252e"), Color("#485064")],
]

const NPCS_PER_SEGMENT := 6

func _ready() -> void:
	var terrain = TerrainScript.new()
	terrain.name = "SoilTerrain"
	add_child(terrain)

	var world_light = WorldLightScript.new()
	world_light.name = "WorldLightManager"
	add_child(world_light)

	var street_walk = StreetWalkScript.new()
	street_walk.name = "StreetWalk"
	add_child(street_walk)

	var road = RoadScript.new()
	road.name = "RoadLayer"
	add_child(road)
	road.configure(street_walk.get_route())

	var central_plaza = CentralPlazaScript.new()
	central_plaza.name = "CentralStationPlaza"
	add_child(central_plaza)

	var furniture = StreetFurnitureScript.new()
	furniture.name = "StreetFurniture"
	furniture.configure(street_walk.get_route())
	add_child(furniture)

	var player = PlayerScript.new()
	player.name = "DoodlePlayer"
	player.add_to_group("doodles")
	add_child(player)
	# Begin on the outer pedestrian lane instead of inside the widened roadway.
	player.global_position = Vector2(0, 137)

	var camera := Camera2D.new()
	camera.name = "PlayerCamera"
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.0
	camera.zoom = Vector2(1.08, 1.08)
	camera.limit_left = -2850
	camera.limit_right = 2850
	camera.limit_top = -1850
	camera.limit_bottom = 1850
	player.add_child(camera)
	camera.make_current()

	var controls = ControlsScript.new()
	controls.name = "TouchControls"
	controls.layer = 20
	add_child(controls)
	player.controls = controls
	controls.light_manager = world_light

	# Two walking lanes per pavement. Six pedestrians is the official population
	# budget for one camera-sized city segment.
	var lane_offsets := [235.0, 315.0, -235.0, -315.0, 235.0, 315.0]
	var opening_route_indices := [2, 13, 3, 11, 4, 10]
	var segment_npcs: Array = []
	for i in NPCS_PER_SEGMENT:
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
		var reverse_route := i % 2 == 1
		npc.configure_route(pedestrian_route, opening_route_indices[i], 0.45 + float(i % 3) * 0.065, reverse_route)
		npc.configure_behavior_spots(furniture.get_sit_spots(), furniture.get_gather_spots(), i)
		segment_npcs.append(npc)

	# Make the living-street behaviours immediately visible in the first segment.
	var seats := furniture.get_sit_spots()
	var gatherings := furniture.get_gather_spots()
	segment_npcs[3].start_behavior_at("sit", seats[0], Vector2(0, -1))
	segment_npcs[4].start_behavior_at("talk", gatherings[0] + Vector2(-40, 0), Vector2.RIGHT)
	segment_npcs[5].start_behavior_at("talk", gatherings[0] + Vector2(40, 0), Vector2.LEFT)

	# A small traffic pack: two same-direction cars and a bus share one lane,
	# while the third car uses the opposite lane and route direction.
	var traffic_specs := [
		["TrafficCarRed", "car", 0, -95.0, 3, false],
		["TrafficCarBlue", "car", 1, -95.0, 9, false],
		["CityBus", "bus", 0, -95.0, 14, false],
		["TrafficCarGold", "car", 2, 95.0, 5, true]
	]
	for spec in traffic_specs:
		var vehicle = TrafficCarScript.new()
		vehicle.name = spec[0]
		vehicle.setup(spec[1], spec[2])
		add_child(vehicle)
		var vehicle_route: PackedVector2Array = road.get_vehicle_route(spec[3])
		if spec[5]: vehicle_route.reverse()
		vehicle.configure(vehicle_route, spec[4])

	var activity_manager = ActivityManagerScript.new()
	activity_manager.name = "WorldActivityManager"
	activity_manager.player = player
	add_child(activity_manager)

	# Procedural CanvasItems must receive an initial draw before any movement.
	# This is especially important on the Web renderer where the first frame can
	# otherwise contain only the terrain and CanvasLayer HUD.
	player.visual.queue_redraw()
	street_walk.queue_redraw()
	road.queue_redraw()
	furniture.queue_redraw()
