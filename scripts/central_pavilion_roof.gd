extends Node2D

const STATION_TEXTURE = preload("res://assets/environment/central_station.png")

var light_manager
var building_center := Vector2.ZERO
var tree_positions := PackedVector2Array()

func _ready() -> void:
	z_index = 12
	add_to_group("world_lit_visual")
	var station_roof := Sprite2D.new()
	station_roof.name = "RasterCentralStationRoof"
	# Fit the actual opaque building, not the generated canvas's transparent margin.
	var cropped := AtlasTexture.new()
	cropped.atlas = STATION_TEXTURE
	cropped.region = STATION_TEXTURE.get_image().get_used_rect()
	station_roof.texture = cropped
	station_roof.scale = Vector2(390.0 / cropped.get_width(), 233.0 / cropped.get_height())
	station_roof.position = building_center + Vector2(0, 8)
	station_roof.z_as_relative = false; station_roof.z_index = 12
	add_child(station_roof)
	queue_redraw()

func _draw() -> void:
	# The compact station is one clean-alpha raster with no baked ground shadow;
	# only the existing tree canopies remain
	# procedural until the dedicated foliage-art pass.
	for position in tree_positions:
		draw_circle(position + Vector2(0, -5), 57.0, Color("#244b31"))
		draw_circle(position + Vector2(-23, -14), 36.0, Color("#376b3b"))
		draw_circle(position + Vector2(22, -18), 39.0, Color("#4e8044"))
		draw_circle(position + Vector2(2, -30), 32.0, Color("#669650"))
		if is_instance_valid(light_manager) and light_manager.is_night(): draw_circle(position + Vector2(-16, -22), 4.0, Color(1.0, 0.84, 0.47, 0.70))
