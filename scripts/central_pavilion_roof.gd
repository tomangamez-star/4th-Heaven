extends Node2D

var light_manager
var building_center := Vector2.ZERO
var tree_positions := PackedVector2Array()

func _ready() -> void:
	z_index = 12
	add_to_group("world_lit_visual")
	queue_redraw()

func _draw() -> void:
	# Wide Japanese-inspired stepped roof above characters.
	draw_colored_polygon(PackedVector2Array([building_center + Vector2(-282, -112), building_center + Vector2(-230, -158), building_center + Vector2(230, -158), building_center + Vector2(282, -112), building_center + Vector2(258, -76), building_center + Vector2(-258, -76)]), Color("#372f34"))
	draw_colored_polygon(PackedVector2Array([building_center + Vector2(-254, -111), building_center + Vector2(-212, -145), building_center + Vector2(212, -145), building_center + Vector2(254, -111), building_center + Vector2(233, -88), building_center + Vector2(-233, -88)]), Color("#80433e"))
	draw_line(building_center + Vector2(-252, -108), building_center + Vector2(252, -108), Color("#c27657"), 7.0, true)
	for x in range(-190, 191, 38): draw_line(building_center + Vector2(x, -139), building_center + Vector2(x + 14, -91), Color(0.98, 0.69, 0.48, 0.18), 3.0)
	for position in tree_positions:
		draw_circle(position + Vector2(0, -5), 57.0, Color("#244b31"))
		draw_circle(position + Vector2(-23, -14), 36.0, Color("#376b3b"))
		draw_circle(position + Vector2(22, -18), 39.0, Color("#4e8044"))
		draw_circle(position + Vector2(2, -30), 32.0, Color("#669650"))
		if is_instance_valid(light_manager) and light_manager.is_night(): draw_circle(position + Vector2(-16, -22), 4.0, Color(1.0, 0.84, 0.47, 0.70))
