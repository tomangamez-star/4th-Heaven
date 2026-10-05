extends Node2D

const PlayerScript = preload("res://scripts/doodle_player.gd")
const TerrainScript = preload("res://scripts/soil_terrain.gd")
const ControlsScript = preload("res://scripts/touch_controls.gd")

func _ready() -> void:
	var terrain = TerrainScript.new()
	terrain.name = "SoilTerrain"
	add_child(terrain)

	var player = PlayerScript.new()
	player.name = "DoodlePlayer"
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
