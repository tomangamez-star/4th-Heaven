extends Node2D

var light_manager
var building_center := Vector2.ZERO
var tree_positions := PackedVector2Array()

func _ready() -> void:
	z_index = 12
	add_to_group("world_lit_visual")
	queue_redraw()

func _draw() -> void:
	# A genuine overhead hipped roof: the roof plane dominates the footprint,
	# while the tiny north entrance is visible beneath its front eave.
	var outer := PackedVector2Array([
		building_center + Vector2(-270, -128), building_center + Vector2(270, -128),
		building_center + Vector2(250, 122), building_center + Vector2(-250, 122)
	])
	draw_colored_polygon(outer, Color("#352d32"))
	var roof := PackedVector2Array([
		building_center + Vector2(-250, -111), building_center + Vector2(250, -111),
		building_center + Vector2(231, 105), building_center + Vector2(-231, 105)
	])
	draw_colored_polygon(roof, Color("#81453f"))
	var ridge_left := building_center + Vector2(-122, -18)
	var ridge_right := building_center + Vector2(122, -18)
	draw_colored_polygon(PackedVector2Array([
		building_center + Vector2(-250, -111), ridge_left, ridge_left + Vector2(0, 54), building_center + Vector2(-231, 105)
	]), Color("#6d3c3b"))
	draw_colored_polygon(PackedVector2Array([
		ridge_right, building_center + Vector2(250, -111), building_center + Vector2(231, 105), ridge_right + Vector2(0, 54)
	]), Color("#955047"))
	draw_rect(Rect2(building_center + Vector2(-122, -48), Vector2(244, 82)), Color("#a55b4d"), true)
	draw_line(building_center + Vector2(-122, -48), building_center + Vector2(122, -48), Color("#d18462"), 6.0, true)
	draw_line(building_center + Vector2(-122, 34), building_center + Vector2(122, 34), Color("#5a3033"), 5.0, true)
	for x in range(-218, 219, 34):
		draw_line(building_center + Vector2(x, -103), building_center + Vector2(x * 0.53, -48), Color(1.0, 0.72, 0.52, 0.17), 3.0)
		draw_line(building_center + Vector2(x * 0.53, 34), building_center + Vector2(x, 96), Color(0.20, 0.10, 0.11, 0.18), 3.0)
	# Small station emblem sits flat on the roof rather than on an upright wall.
	draw_rect(Rect2(building_center + Vector2(-54, 48), Vector2(108, 31)), Color("#e4d4b7"), true)
	draw_circle(building_center + Vector2(0, 63), 9.0, Color("#b94e42"))
	draw_line(building_center + Vector2(-37, 63), building_center + Vector2(-14, 63), Color("#466168"), 5.0, true)
	draw_line(building_center + Vector2(14, 63), building_center + Vector2(37, 63), Color("#466168"), 5.0, true)
	for position in tree_positions:
		draw_circle(position + Vector2(0, -5), 57.0, Color("#244b31"))
		draw_circle(position + Vector2(-23, -14), 36.0, Color("#376b3b"))
		draw_circle(position + Vector2(22, -18), 39.0, Color("#4e8044"))
		draw_circle(position + Vector2(2, -30), 32.0, Color("#669650"))
		if is_instance_valid(light_manager) and light_manager.is_night(): draw_circle(position + Vector2(-16, -22), 4.0, Color(1.0, 0.84, 0.47, 0.70))
