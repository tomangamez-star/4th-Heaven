extends Node2D

var light_manager

var bench_spots := PackedVector2Array([
	Vector2(-330, 154), Vector2(330, 154),
	Vector2(-1010, 154), Vector2(1010, 154),
	Vector2(-580, 1005), Vector2(580, 1005)
])
var bus_stop_spots := PackedVector2Array([
	Vector2(720, 150), Vector2(-780, 150)
])
var gather_spots := PackedVector2Array([
	Vector2(250, 104), Vector2(-520, 104), Vector2(0, 995)
])
var streetlight_spots := PackedVector2Array([
	Vector2(-1180, 176), Vector2(-590, 176), Vector2(0, 176),
	Vector2(590, 176), Vector2(1180, 176)
])

func _ready() -> void:
	z_index = 4
	add_to_group("street_furniture")
	var lights := get_tree().get_nodes_in_group("world_light")
	if not lights.is_empty():
		light_manager = lights[0]
	queue_redraw()

func get_sit_spots() -> PackedVector2Array:
	var result := PackedVector2Array()
	for bench in bench_spots:
		result.append(bench + Vector2(-27, -3))
		result.append(bench + Vector2(27, -3))
	return result

func get_gather_spots() -> PackedVector2Array:
	return gather_spots.duplicate()

func _shadow_offset(height: float) -> Vector2:
	if is_instance_valid(light_manager):
		return light_manager.get_shadow_offset(height)
	return Vector2(10, 15)

func _shadow_color(alpha_scale: float = 1.0) -> Color:
	if is_instance_valid(light_manager):
		return light_manager.get_shadow_color(alpha_scale)
	return Color(0.08, 0.05, 0.03, 0.28 * alpha_scale)

func _draw() -> void:
	for position in bench_spots:
		_draw_bench(position)
	for position in bus_stop_spots:
		_draw_bus_stop(position)
	for position in streetlight_spots:
		_draw_streetlight(position)
	for position in [Vector2(-455, 170), Vector2(455, 170), Vector2(880, 170)]:
		_draw_bin(position)
	_draw_road_sign(Vector2(-1120, 98), "BUS")
	_draw_road_sign(Vector2(1120, 98), "LOOP")

func _draw_bench(position: Vector2) -> void:
	var shadow := _shadow_offset(8.0)
	draw_rect(Rect2(position + shadow - Vector2(65, 20), Vector2(130, 40)), _shadow_color(0.75), true)
	draw_rect(Rect2(position - Vector2(68, 23), Vector2(136, 46)), Color("#563423"), true)
	draw_rect(Rect2(position - Vector2(64, 19), Vector2(128, 38)), Color("#a5673f"), true)
	for y in [-11.0, 0.0, 11.0]:
		draw_line(position + Vector2(-59, y), position + Vector2(59, y), Color("#d0925e"), 5.0, true)
	draw_circle(position + Vector2(-52, 19), 5.0, Color("#30353a"))
	draw_circle(position + Vector2(52, 19), 5.0, Color("#30353a"))

func _draw_bus_stop(position: Vector2) -> void:
	var shadow := _shadow_offset(16.0)
	draw_rect(Rect2(position + shadow - Vector2(93, 43), Vector2(186, 86)), _shadow_color(0.85), true)
	draw_rect(Rect2(position - Vector2(96, 46), Vector2(192, 92)), Color("#35444b"), true)
	draw_rect(Rect2(position - Vector2(90, 40), Vector2(180, 80)), Color(0.36, 0.64, 0.68, 0.48), true)
	draw_line(position + Vector2(-90, -40), position + Vector2(-90, 40), Color("#d6c4a4"), 7.0, true)
	draw_line(position + Vector2(90, -40), position + Vector2(90, 40), Color("#d6c4a4"), 7.0, true)
	draw_rect(Rect2(position + Vector2(-58, 12), Vector2(116, 20)), Color("#9b633e"), true)
	draw_rect(Rect2(position + Vector2(-94, -50), Vector2(188, 14)), Color("#e0cda9"), true)

func _draw_streetlight(position: Vector2) -> void:
	var shadow_end := position + _shadow_offset(27.0)
	draw_line(position, shadow_end, _shadow_color(0.85), 10.0, true)
	draw_circle(shadow_end, 10.0, _shadow_color(0.7))
	draw_circle(position, 11.0, Color("#30353b"))
	draw_circle(position, 7.0, Color("#7f8990"))
	draw_circle(position + Vector2(0, -2), 3.0, Color("#ffe1a0"))

func _draw_bin(position: Vector2) -> void:
	var shadow := _shadow_offset(7.0)
	draw_circle(position + shadow, 17.0, _shadow_color(0.65))
	draw_circle(position, 17.0, Color("#315a51"))
	draw_circle(position, 13.0, Color("#4c8072"))
	draw_line(position + Vector2(-10, -3), position + Vector2(10, -3), Color("#a8c2a9"), 3.0, true)

func _draw_road_sign(position: Vector2, label: String) -> void:
	var shadow_end := position + _shadow_offset(19.0)
	draw_line(position, shadow_end, _shadow_color(0.7), 7.0, true)
	draw_circle(position, 8.0, Color("#4b5055"))
	draw_rect(Rect2(position + Vector2(-29, -33), Vector2(58, 25)), Color("#277b86"), true)
	draw_rect(Rect2(position + Vector2(-29, -33), Vector2(58, 25)), Color("#d8f1ee"), false, 3.0)
	# Tiny geometric lettering keeps the sign readable without font assets.
	var bars := 3 if label == "BUS" else 4
	for i in bars:
		draw_rect(Rect2(position + Vector2(-20 + i * 11, -25), Vector2(7, 8)), Color("#e9f8f4"), true)
