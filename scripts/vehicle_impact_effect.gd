extends Node2D

var lifetime := 0.0
var direction := Vector2.UP

func _ready() -> void:
	z_index = 16
	queue_redraw()

func _process(delta: float) -> void:
	lifetime += delta
	queue_redraw()
	if lifetime >= 0.42: queue_free()

func _draw() -> void:
	var progress := clampf(lifetime / 0.42, 0.0, 1.0)
	var alpha := 1.0 - progress
	draw_arc(Vector2.ZERO, 18.0 + progress * 42.0, 0.0, TAU, 28, Color(1.0, 0.82, 0.45, alpha * 0.72), 5.0 - progress * 3.0)
	for index in 8:
		var ray := direction.rotated((float(index) - 3.5) * 0.42 + sin(float(index) * 4.7) * 0.18)
		var start := ray * (13.0 + progress * 10.0)
		var finish := ray * (31.0 + progress * 42.0)
		draw_line(start, finish, Color(1.0, 0.57 + float(index % 2) * 0.20, 0.22, alpha), 4.0, true)
	for index in 5:
		var dust_direction := Vector2.RIGHT.rotated(float(index) * TAU / 5.0)
		draw_circle(dust_direction * (12.0 + progress * 34.0), 7.0 * alpha, Color(0.56, 0.48, 0.38, alpha * 0.45))
