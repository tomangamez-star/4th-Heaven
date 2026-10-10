extends Node2D

const RoofScript = preload("res://scripts/central_pavilion_roof.gd")
const Foliage = preload("res://scripts/foliage_atlas.gd")

var light_manager
var lawn_boundary := PackedVector2Array()
var building_center := Vector2(0, 430)
var tree_positions := PackedVector2Array([Vector2(-760, 250), Vector2(760, 250), Vector2(-760, 610), Vector2(760, 610)])
var bush_positions := PackedVector2Array([Vector2(-560, 205), Vector2(560, 205), Vector2(-560, 660), Vector2(560, 660), Vector2(-900, 430), Vector2(900, 430)])

func configure(inner_sidewalk_edge: PackedVector2Array) -> void:
	lawn_boundary = inner_sidewalk_edge.duplicate()

func _ready() -> void:
	z_index = -2
	add_to_group("world_lit_visual")
	var lights := get_tree().get_nodes_in_group("world_light")
	if not lights.is_empty(): light_manager = lights[0]
	_create_collisions()
	var roof = RoofScript.new(); roof.name = "PavilionRoofAndCanopies"; roof.light_manager = light_manager
	roof.building_center = building_center; roof.tree_positions = tree_positions; add_child(roof)
	queue_redraw()

func _draw() -> void:
	# The lawn follows the actual inner loop instead of exposing a rectangular
	# soil ring at the angled road corners. It slightly underlaps the sidewalk.
	if lawn_boundary.size() >= 3:
		draw_colored_polygon(lawn_boundary, Color("#466f3f"))
		var lawn_inner := PackedVector2Array()
		for point in lawn_boundary:
			lawn_inner.append(point.lerp(building_center, 0.025))
		draw_colored_polygon(lawn_inner, Color("#5b8b4b"))
	# Raster grass and flower clusters replace the old translucent vector circles.
	for x in range(-900, 901, 180):
		for y in range(215, 671, 115):
			if absf(float(x)) < 175.0: continue
			var size := Vector2(112, 78) * (0.88 + float(posmod(x + y, 5)) * 0.035)
			draw_texture_rect(Foliage.get_part(3), Rect2(Vector2(x, y) - size * 0.5, size), false, Color(1, 1, 1, 0.42))
	for flower in [Vector2(-650, 350), Vector2(-505, 575), Vector2(540, 305), Vector2(690, 550), Vector2(-330, 235), Vector2(360, 620)]:
		draw_texture_rect(Foliage.get_part(2), Rect2(flower - Vector2(34, 24), Vector2(68, 48)), false)
	# Wide stone walk connects both sidewalks through the station forecourt.
	draw_rect(Rect2(-92, 170, 184, 520), Color("#aa9b83"), true)
	draw_rect(Rect2(-78, 170, 156, 520), Color("#d0c1a7"), true)
	for y in range(190, 681, 52): draw_line(Vector2(-76, y), Vector2(76, y), Color(0.30, 0.24, 0.18, 0.18), 2.0)
	draw_circle(building_center, 350.0, Color("#c9b99e")); draw_circle(building_center, 326.0, Color("#d8c8ac"))
	for position in tree_positions: _draw_tree_base(position)
	for position in bush_positions: _draw_bush(position)

func _rounded_box(color: Color, radius: float) -> StyleBoxFlat:
	var box := StyleBoxFlat.new(); box.bg_color = color
	box.corner_radius_top_left = int(radius); box.corner_radius_top_right = int(radius)
	box.corner_radius_bottom_left = int(radius); box.corner_radius_bottom_right = int(radius)
	return box

func _draw_tree_base(position: Vector2) -> void:
	var shadow: Vector2 = light_manager.get_shadow_offset(25.0) if is_instance_valid(light_manager) else Vector2(16, 22)
	draw_colored_polygon(PackedVector2Array([position + Vector2(-11, 0), position + Vector2(11, 0), position + shadow + Vector2(34, 18), position + shadow + Vector2(-34, 18)]), Color(0.08, 0.05, 0.03, 0.24))
	draw_circle(position, 19.0, Color("#5a3a25")); draw_circle(position, 11.0, Color("#9a6740"))

func _draw_bush(position: Vector2) -> void:
	var shadow: Vector2 = light_manager.get_shadow_offset(7.0) if is_instance_valid(light_manager) else Vector2(5, 7)
	draw_texture_rect(Foliage.get_part(1), Rect2(position + shadow - Vector2(39, 30), Vector2(78, 60)), false, Color(0.03, 0.04, 0.02, 0.24))
	draw_texture_rect(Foliage.get_part(1), Rect2(position - Vector2(38, 34), Vector2(76, 68)), false)

func _create_collisions() -> void:
	var holder := Node2D.new(); holder.name = "PlazaCollisions"; add_child(holder)
	# Three wall bodies follow the enlarged station silhouette while leaving the
	# front steps, awning shadow and doorway walkable.
	# Tight wall strips follow only opaque masonry. The awning, steps and PNG
	# shadow never create an invisible collision wall.
	_add_box(holder, building_center + Vector2(0, -54), Vector2(560, 118), "StationRear")
	_add_box(holder, building_center + Vector2(-238, 57), Vector2(142, 80), "StationLeftWing")
	_add_box(holder, building_center + Vector2(238, 57), Vector2(142, 80), "StationRightWing")
	for position in tree_positions: _add_circle(holder, position, 30.0, "Tree")
	for position in bush_positions: _add_circle(holder, position, 25.0, "Bush")

func _add_box(parent: Node, position: Vector2, size: Vector2, label: String) -> void:
	var body := StaticBody2D.new(); body.name = label; body.position = position
	var node := CollisionShape2D.new(); var shape := RectangleShape2D.new(); shape.size = size; node.shape = shape
	body.add_child(node); parent.add_child(body)

func _add_circle(parent: Node, position: Vector2, radius: float, label: String) -> void:
	var body := StaticBody2D.new(); body.name = label; body.position = position
	var node := CollisionShape2D.new(); var shape := CircleShape2D.new(); shape.radius = radius; node.shape = shape
	body.add_child(node); parent.add_child(body)
