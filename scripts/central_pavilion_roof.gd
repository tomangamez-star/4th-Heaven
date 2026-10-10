extends Node2D

const STATION_TEXTURE = preload("res://assets/environment/central_station.png")
const Foliage = preload("res://scripts/foliage_atlas.gd")

var light_manager
var building_center := Vector2.ZERO
var tree_positions := PackedVector2Array()
var station_roof: Sprite2D
var station_shadow: Sprite2D

func _ready() -> void:
	z_index = 12
	add_to_group("world_lit_visual")
	station_shadow = Sprite2D.new()
	station_shadow.name = "StationSilhouetteShadow"
	station_roof = Sprite2D.new()
	station_roof.name = "RasterCentralStationRoof"
	# Fit the actual opaque building, not the generated canvas's transparent margin.
	var cropped := AtlasTexture.new()
	cropped.atlas = STATION_TEXTURE
	cropped.region = STATION_TEXTURE.get_image().get_used_rect()
	station_roof.texture = cropped
	station_roof.scale = Vector2(560.0 / cropped.get_width(), 312.0 / cropped.get_height())
	station_roof.position = building_center + Vector2(0, 8)
	station_roof.z_as_relative = false; station_roof.z_index = 12
	station_shadow.texture = cropped
	station_shadow.scale = station_roof.scale
	station_shadow.modulate = Color(0.035, 0.025, 0.02, 0.30)
	station_shadow.z_as_relative = false; station_shadow.z_index = 3
	add_child(station_shadow)
	add_child(station_roof)
	_update_shadow()
	if is_instance_valid(light_manager):
		light_manager.time_state_changed.connect(func(_state): _update_shadow())
	queue_redraw()

func _draw() -> void:
	for position in tree_positions:
		draw_texture_rect(Foliage.get_part(0), Rect2(position - Vector2(73, 78), Vector2(146, 146)), false)

func _update_shadow() -> void:
	if not is_instance_valid(station_shadow): return
	var offset: Vector2 = light_manager.get_shadow_offset(20.0) if is_instance_valid(light_manager) else Vector2(12, 17)
	station_shadow.position = building_center + Vector2(0, 8) + offset
	station_shadow.modulate = light_manager.get_shadow_color(0.95) if is_instance_valid(light_manager) else Color(0.035, 0.025, 0.02, 0.28)
