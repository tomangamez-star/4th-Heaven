extends Control

var controls

func _draw() -> void:
	if not is_instance_valid(controls):
		return
	var jc: Vector2 = controls.joystick_center
	var jk: Vector2 = controls.joystick_knob
	var rc: Vector2 = controls.run_center
	draw_circle(jc, 86.0, Color(0.035, 0.045, 0.055, 0.34))
	draw_circle(jc, 84.0, Color(0.84, 0.94, 0.95, 0.10), false, 3.0)
	draw_circle(jk, 37.0, Color(0.87, 0.96, 0.97, 0.31))
	draw_circle(jk, 36.0, Color(0.92, 1.0, 1.0, 0.18), false, 2.0)

	var run_fill := Color(0.08, 0.66, 0.74, 0.46) if controls.run_pressed else Color(0.035, 0.045, 0.055, 0.38)
	draw_circle(rc, 59.0, run_fill)
	draw_circle(rc, 57.0, Color(0.85, 0.97, 0.98, 0.18), false, 3.0)
	# Simple running-person glyph, drawn in code to avoid external icon assets.
	var ink := Color(0.94, 1.0, 1.0, 0.82)
	draw_circle(rc + Vector2(8, -22), 7.0, ink)
	draw_line(rc + Vector2(4, -14), rc + Vector2(-4, 5), ink, 7.0, true)
	draw_line(rc + Vector2(0, -6), rc + Vector2(-20, -1), ink, 6.0, true)
	draw_line(rc + Vector2(-3, 4), rc + Vector2(-22, 23), ink, 7.0, true)
	draw_line(rc + Vector2(-3, 3), rc + Vector2(19, 20), ink, 7.0, true)
