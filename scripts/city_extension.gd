extends Node2D

var east_road := PackedVector2Array([Vector2(1420, 440), Vector2(2860, 440)])
var north_road := PackedVector2Array([Vector2(2350, -1500), Vector2(2350, 1500)])
var park_spur := PackedVector2Array([Vector2(2350, -760), Vector2(2050, -760)])

func _ready() -> void:
	z_index = -2
	_create_world_boundaries()
	queue_redraw()

func get_extension_traffic_route() -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(1520, 345), Vector2(2050, 345), Vector2(2350, 345), Vector2(2760, 345),
		Vector2(2840, 440), Vector2(2760, 535), Vector2(2445, 535), Vector2(2445, 1320),
		Vector2(2350, 1420), Vector2(2255, 1320), Vector2(2255, 535), Vector2(1520, 535)
	])

func _draw() -> void:
	for path in [east_road, north_road, park_spur]: _draw_walk_path(path)
	for path in [east_road, north_road, park_spur]: _draw_asphalt_path(path)
	_draw_parking_court()

func _draw_walk_path(path: PackedVector2Array) -> void:
	_draw_open_path(path, Color(0.18, 0.10, 0.055, 0.28), 820.0)
	_draw_open_path(path, Color("#625548"), 792.0)
	_draw_open_path(path, Color("#b7a58d"), 758.0)
	_draw_open_path(path, Color("#c8b79d"), 730.0)

func _draw_asphalt_path(path: PackedVector2Array) -> void:
	_draw_open_path(path, Color(0.12, 0.07, 0.04, 0.30), 430.0)
	_draw_open_path(path, Color("#57585a"), 410.0)
	_draw_open_path(path, Color("#34373b"), 380.0)
	var a := path[0]; var b := path[path.size() - 1]
	draw_dashed_line(a, b, Color(0.96, 0.82, 0.46, 0.66), 5.0, 92.0, true)

func _draw_open_path(path: PackedVector2Array, color: Color, width: float) -> void:
	draw_polyline(path, color, width, true)
	for point in path: draw_circle(point, width * 0.5, color)

func _draw_parking_court() -> void:
	var lot := Rect2(1570, -1035, 610, 550)
	draw_style_box(_rounded(Color(0.12, 0.07, 0.04, 0.28), 42), lot.grow(24))
	draw_style_box(_rounded(Color("#57585a"), 36), lot.grow(12))
	draw_style_box(_rounded(Color("#34373b"), 30), lot)
	for column in 3:
		var x := 1640.0 + column * 180.0
		draw_line(Vector2(x, -970), Vector2(x, -620), Color(0.94, 0.90, 0.77, 0.58), 5.0, true)
		draw_line(Vector2(x + 140, -970), Vector2(x + 140, -620), Color(0.94, 0.90, 0.77, 0.58), 5.0, true)
		draw_line(Vector2(x + 24, -640), Vector2(x + 116, -640), Color("#77716a"), 10.0, true)

func _rounded(color: Color, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new(); box.bg_color = color; box.set_corner_radius_all(radius)
	return box

func _create_world_boundaries() -> void:
	var holder := Node2D.new(); holder.name = "WorldBoundaries"; add_child(holder)
	_add_wall(holder, Vector2(-3040, 0), Vector2(80, 4000))
	_add_wall(holder, Vector2(3040, 0), Vector2(80, 4000))
	_add_wall(holder, Vector2(0, -2040), Vector2(6080, 80))
	_add_wall(holder, Vector2(0, 2040), Vector2(6080, 80))

func _add_wall(parent: Node, position: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new(); body.position = position
	var collider := CollisionShape2D.new(); var shape := RectangleShape2D.new(); shape.size = size
	collider.shape = shape; body.add_child(collider); parent.add_child(body)
