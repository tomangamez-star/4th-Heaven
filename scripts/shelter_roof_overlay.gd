extends Node2D

var light_manager

func _ready() -> void:
	z_index = 12
	queue_redraw()

func _draw() -> void:
	# Blue glass stays transparent enough to see heads, hair and clothing below.
	draw_rect(Rect2(-113, -63, 226, 126), Color(0.07, 0.16, 0.19, 0.76), true)
	draw_rect(Rect2(-105, -55, 210, 110), Color(0.20, 0.63, 0.72, 0.25), true)
	draw_line(Vector2(-100, 42), Vector2(86, -50), Color(0.82, 0.96, 1.0, 0.30), 5.0, true)
	draw_line(Vector2(-86, 52), Vector2(101, -40), Color(0.82, 0.96, 1.0, 0.17), 2.0, true)
	draw_rect(Rect2(-113, -63, 226, 126), Color("#d6c7aa"), false, 7.0)
	draw_line(Vector2(-108, -59), Vector2(108, -59), Color(0.90, 0.84, 0.70, 0.72), 3.0, true)
