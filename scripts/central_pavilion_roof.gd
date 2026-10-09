extends Node2D

const STATION_TEXTURE = preload("res://assets/environment/central_station.png")
const STATION_ROOF_TEXTURE = preload("res://assets/environment/central_station_roof.png")

var light_manager
var building_center := Vector2.ZERO
var tree_positions := PackedVector2Array()

func _ready() -> void:
	z_index = 12
	add_to_group("world_lit_visual")
	var station_base := Sprite2D.new()
	station_base.name = "RasterCentralStationBase"
	station_base.texture = STATION_TEXTURE
	station_base.position = building_center + Vector2(0, 8)
	station_base.z_as_relative = false; station_base.z_index = 0
	add_child(station_base)
	var station_roof := Sprite2D.new()
	station_roof.name = "RasterCentralStationRoof"
	station_roof.texture = STATION_ROOF_TEXTURE
	station_roof.position = building_center + Vector2(0, 8)
	station_roof.z_as_relative = false; station_roof.z_index = 12
	add_child(station_roof)
	queue_redraw()

func _draw() -> void:
	# The station is raster artwork; only the existing tree canopies remain
	# procedural until the dedicated foliage-art pass.
	for position in tree_positions:
		draw_circle(position + Vector2(0, -5), 57.0, Color("#244b31"))
		draw_circle(position + Vector2(-23, -14), 36.0, Color("#376b3b"))
		draw_circle(position + Vector2(22, -18), 39.0, Color("#4e8044"))
		draw_circle(position + Vector2(2, -30), 32.0, Color("#669650"))
		if is_instance_valid(light_manager) and light_manager.is_night(): draw_circle(position + Vector2(-16, -22), 4.0, Color(1.0, 0.84, 0.47, 0.70))
