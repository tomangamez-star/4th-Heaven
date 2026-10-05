extends Node2D

var route := PackedVector2Array([
	Vector2(-1180, 340),
	Vector2(-720, 340),
	Vector2(-430, 140),
	Vector2(-430, -360),
	Vector2(-120, -610),
	Vector2(520, -610),
	Vector2(980, -250),
	Vector2(980, 330),
	Vector2(570, 610),
	Vector2(-250, 610),
	Vector2(-720, 340)
])

func _ready() -> void:
	z_index = -4
	queue_redraw()

func get_route() -> PackedVector2Array:
	return route.duplicate()

func _draw() -> void:
	# Each stroke is its own layer: shadow, curb, pavement and inner wear.
	_draw_closed_path(Color(0.18, 0.10, 0.055, 0.28), 226.0)
	_draw_closed_path(Color("#625548"), 204.0)
	_draw_closed_path(Color("#b7a58d"), 178.0)
	_draw_closed_path(Color("#c8b79d"), 150.0)
	_draw_closed_path(Color(0.35, 0.27, 0.20, 0.17), 3.0)

	# Sparse seams make the street-walk readable without becoming realistic.
	for i in route.size():
		var point := route[i]
		var previous := route[(i - 1 + route.size()) % route.size()]
		var next := route[(i + 1) % route.size()]
		var direction := (next - previous).normalized()
		var normal := Vector2(-direction.y, direction.x)
		draw_line(point - normal * 66.0, point + normal * 66.0, Color(0.30, 0.23, 0.18, 0.20), 3.0, true)
		draw_circle(point + normal * 38.0, 4.0, Color(1.0, 0.91, 0.76, 0.18))

func _draw_closed_path(color: Color, width: float) -> void:
	var closed := route.duplicate()
	closed.append(route[0])
	draw_polyline(closed, color, width, true)
	# Rounded joints keep every turn looking intentionally illustrated.
	for point in route:
		draw_circle(point, width * 0.5, color)
