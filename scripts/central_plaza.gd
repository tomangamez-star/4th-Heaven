extends Node2D

const RoofScript = preload("res://scripts/central_pavilion_roof.gd")

var light_manager
var lawn_boundary := PackedVector2Array()
var building_center := Vector2(0, 430)
var tree_positions := PackedVector2Array([Vector2(-690, 285), Vector2(690, 285), Vector2(-690, 570), Vector2(690, 570)])
var bush_positions := PackedVector2Array([Vector2(-475, 225), Vector2(475, 225), Vector2(-475, 625), Vector2(475, 625), Vector2(-820, 430), Vector2(820, 430)])

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
	for x in range(-850, 851, 170):
		for y in range(235, 651, 105):
			var wave := sin(float(x) * 0.012 + float(y) * 0.017)
			draw_circle(Vector2(x, y), 54.0, Color(0.18, 0.34, 0.16, 0.08 + absf(wave) * 0.04))
	for flower in [Vector2(-760, 350), Vector2(-575, 560), Vector2(590, 310), Vector2(760, 530), Vector2(-340, 245), Vector2(350, 610)]:
		draw_circle(flower, 5.0, Color("#f1d58a")); draw_circle(flower + Vector2(5, 2), 3.0, Color("#e59b91"))
	# Wide stone walk connects both sidewalks through the station forecourt.
	draw_rect(Rect2(-92, 170, 184, 520), Color("#aa9b83"), true)
	draw_rect(Rect2(-78, 170, 156, 520), Color("#d0c1a7"), true)
	for y in range(190, 681, 52): draw_line(Vector2(-76, y), Vector2(76, y), Color(0.30, 0.24, 0.18, 0.18), 2.0)
	draw_circle(building_center, 275.0, Color("#c9b99e")); draw_circle(building_center, 250.0, Color("#d8c8ac"))
	_draw_building_base()
	for position in tree_positions: _draw_tree_base(position)
	for position in bush_positions: _draw_bush(position)

func _rounded_box(color: Color, radius: float) -> StyleBoxFlat:
	var box := StyleBoxFlat.new(); box.bg_color = color
	box.corner_radius_top_left = int(radius); box.corner_radius_top_right = int(radius)
	box.corner_radius_bottom_left = int(radius); box.corner_radius_bottom_right = int(radius)
	return box

func _draw_building_base() -> void:
	var shadow: Vector2 = light_manager.get_shadow_offset(22.0) if is_instance_valid(light_manager) else Vector2(18, 24)
	draw_rect(Rect2(building_center + shadow - Vector2(255, 126), Vector2(510, 252)), Color(0.08, 0.05, 0.03, 0.28), true)
	# Only the foundation lip, entrance stair and closed gate remain visible;
	# the roof overlay now owns almost the entire eagle-eye silhouette.
	draw_rect(Rect2(building_center - Vector2(246, 116), Vector2(492, 232)), Color("#4a4039"), true)
	draw_rect(Rect2(building_center - Vector2(233, 104), Vector2(466, 208)), Color("#cdbd9f"), true)
	for step in 4:
		draw_rect(Rect2(building_center + Vector2(-112 + step * 9, -164 + step * 12), Vector2(224 - step * 18, 12)), Color("#d9cbb1").darkened(float(step) * 0.035), true)
	draw_rect(Rect2(building_center + Vector2(-84, -116), Vector2(168, 52)), Color("#17252b"), true)
	for x in range(-72, 73, 18): draw_line(building_center + Vector2(x, -113), building_center + Vector2(x, -68), Color("#829397"), 4.0)
	draw_rect(Rect2(building_center + Vector2(-98, -62), Vector2(196, 19)), Color("#a44a39"), true)
	for x in range(-86, 87, 28): draw_line(building_center + Vector2(x, -59), building_center + Vector2(x + 15, -46), Color("#f0cf67"), 4.0)
	if is_instance_valid(light_manager) and light_manager.is_night():
		draw_circle(building_center + Vector2(-188, 98), 12.0, Color(1.0, 0.78, 0.36, 0.50))
		draw_circle(building_center + Vector2(188, 98), 12.0, Color(1.0, 0.78, 0.36, 0.50))

func _draw_tree_base(position: Vector2) -> void:
	var shadow: Vector2 = light_manager.get_shadow_offset(25.0) if is_instance_valid(light_manager) else Vector2(16, 22)
	draw_colored_polygon(PackedVector2Array([position + Vector2(-11, 0), position + Vector2(11, 0), position + shadow + Vector2(34, 18), position + shadow + Vector2(-34, 18)]), Color(0.08, 0.05, 0.03, 0.24))
	draw_circle(position, 19.0, Color("#5a3a25")); draw_circle(position, 11.0, Color("#9a6740"))

func _draw_bush(position: Vector2) -> void:
	draw_circle(position + Vector2(8, 10), 25.0, Color(0.07, 0.12, 0.05, 0.22))
	draw_circle(position, 24.0, Color("#315f38")); draw_circle(position + Vector2(-9, -5), 16.0, Color("#4b8248")); draw_circle(position + Vector2(10, -7), 13.0, Color("#6a9b55"))

func _create_collisions() -> void:
	var holder := Node2D.new(); holder.name = "PlazaCollisions"; add_child(holder)
	_add_box(holder, building_center, Vector2(490, 248), "StationPavilion")
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
