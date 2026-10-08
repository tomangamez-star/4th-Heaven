extends Control

var controls

func _draw() -> void:
	if not is_instance_valid(controls):
		return
	var jc: Vector2 = controls.joystick_center
	var jk: Vector2 = controls.joystick_knob
	var rc: Vector2 = controls.run_center
	var rag: Vector2 = controls.ragdoll_center
	var push: Vector2 = controls.push_center
	var interact: Vector2 = controls.interact_center
	_draw_time_buttons()
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

	# Temporary physics-test button: a small impact burst above Run.
	draw_circle(rag, 45.0, Color(0.14, 0.07, 0.06, 0.43))
	draw_circle(rag, 43.0, Color(1.0, 0.66, 0.36, 0.24), false, 3.0)
	draw_circle(rag, 10.0, Color(1.0, 0.82, 0.54, 0.88))
	for angle in range(0, 360, 45):
		var direction := Vector2.RIGHT.rotated(deg_to_rad(float(angle)))
		draw_line(rag + direction * 16.0, rag + direction * 29.0, Color(1.0, 0.82, 0.54, 0.82), 4.0, true)

	# Contextual shove control only exists while an available NPC is close.
	if controls.push_visible:
		draw_circle(push, 51.0, Color(0.45, 0.18, 0.12, 0.58))
		draw_circle(push, 49.0, Color(1.0, 0.80, 0.62, 0.30), false, 3.0)
		draw_circle(push + Vector2(10, 0), 13.0, Color(0.97, 0.78, 0.61, 0.92))
		draw_line(push + Vector2(-24, 0), push + Vector2(1, 0), Color(0.97, 0.78, 0.61, 0.92), 9.0, true)
		draw_line(push + Vector2(-18, -13), push + Vector2(0, 0), Color(0.97, 0.78, 0.61, 0.92), 6.0, true)
		draw_line(push + Vector2(-18, 13), push + Vector2(0, 0), Color(0.97, 0.78, 0.61, 0.92), 6.0, true)

	if controls.interact_visible:
		draw_circle(interact, 51.0, Color(0.04, 0.30, 0.36, 0.68))
		draw_circle(interact, 49.0, Color(0.56, 0.94, 0.98, 0.34), false, 3.0)
		# Tiny top-down car/door glyph for enter and exit.
		draw_style_box(_time_box(Color("#dcebee"), Color("#213b42")), Rect2(interact - Vector2(16, 27), Vector2(32, 54)))
		draw_rect(Rect2(interact + Vector2(-10, -15), Vector2(20, 15)), Color("#537580"), true)
		draw_line(interact + Vector2(17, -4), interact + Vector2(31, -4), Color(0.91, 1.0, 1.0, 0.90), 5.0, true)

func _draw_time_buttons() -> void:
	var active := 1
	if is_instance_valid(controls.light_manager): active = controls.light_manager.get_state_index()
	var labels := ["MORN", "AFT", "EVE", "NIGHT"]
	var colors := [Color("#efb56c"), Color("#f5dc72"), Color("#df865f"), Color("#617ab2")]
	for i in controls.time_button_centers.size():
		var center: Vector2 = controls.time_button_centers[i]
		var fill := Color(0.035, 0.045, 0.055, 0.68)
		if i == active: fill = colors[i].darkened(0.35)
		draw_style_box(_time_box(fill, colors[i] if i == active else Color(0.85, 0.92, 0.93, 0.24)), Rect2(center - Vector2(43, 25), Vector2(86, 50)))
		# Simple celestial glyph plus label keeps every state readable on phones.
		if i == 3:
			draw_circle(center + Vector2(-21, -2), 9.0, colors[i])
			draw_circle(center + Vector2(-17, -6), 9.0, fill)
		else:
			draw_circle(center + Vector2(-22, -3), 8.0, colors[i])
			for angle in range(0, 360, 90):
				var direction := Vector2.RIGHT.rotated(deg_to_rad(float(angle)))
				draw_line(center + Vector2(-22, -3) + direction * 11.0, center + Vector2(-22, -3) + direction * 15.0, colors[i], 2.0)
		draw_string(ThemeDB.fallback_font, center + Vector2(-8, 5), labels[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.94, 0.98, 0.98, 0.88))

func _time_box(fill: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new(); box.bg_color = fill; box.border_color = border
	box.set_border_width_all(2); box.set_corner_radius_all(13)
	return box
