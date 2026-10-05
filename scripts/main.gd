extends Node2D

const PlayerScript = preload("res://scripts/doodle_player.gd")
const TerrainScript = preload("res://scripts/soil_terrain.gd")
const ControlsScript = preload("res://scripts/touch_controls.gd")
const WallScript = preload("res://scripts/brick_wall.gd")
const CrateScript = preload("res://scripts/movable_crate.gd")

func _ready() -> void:
	var terrain = TerrainScript.new()
	terrain.name = "SoilTerrain"
	add_child(terrain)

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
	player.add_child(camera)

	var controls = ControlsScript.new()
	controls.name = "TouchControls"
	controls.layer = 20
	add_child(controls)
	player.controls = controls

	var npc = PlayerScript.new()
	npc.name = "TestNPC"
	npc.is_npc = true
	npc.clothing_color = Color("#d76883")
	npc.clothing_dark = Color("#46202d")
	npc.hair_color = Color("#633823")
	npc.add_to_group("doodles")
	npc.add_to_group("npc")
	add_child(npc)
	npc.global_position = Vector2(235, -35)
	npc.home_position = npc.global_position

	var wall = WallScript.new()
	wall.name = "BrickWall"
	add_child(wall)
	wall.global_position = Vector2(315, -205)

	var crate = CrateScript.new()
	crate.name = "MovableCrate"
	add_child(crate)
	crate.global_position = Vector2(150, 145)
