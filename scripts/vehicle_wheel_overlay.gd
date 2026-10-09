extends Node2D

var steer_angle := 0.0
var is_bus := false

func _draw() -> void:
	var x := 62.0 if is_bus else 54.0
	var front_y := -116.0 if is_bus else -69.0
	var rear_y := 116.0 if is_bus else 69.0
	var size := Vector2(13, 37 if is_bus else 31)
	for side in [-1.0, 1.0]:
		draw_set_transform(Vector2(side * x, front_y), steer_angle, Vector2.ONE)
		draw_style_box(_wheel_box(), Rect2(-size * 0.5, size))
		draw_set_transform(Vector2(side * x, rear_y), 0.0, Vector2.ONE)
		draw_style_box(_wheel_box(), Rect2(-size * 0.5, size))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _wheel_box() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color("#111418")
	box.border_color = Color("#343a40")
	box.set_border_width_all(2)
	box.set_corner_radius_all(4)
	return box
