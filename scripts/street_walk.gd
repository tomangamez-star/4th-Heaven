extends Node2D

var route := PackedVector2Array([
	# The opening stretch deliberately crosses the spawn camera. Keeping several
	# route points here also lets pedestrians and traffic begin on-screen.
	Vector2(-1260, -178),
	Vector2(-840, -178),
	Vector2(-420, -178),
	Vector2(0, -178),
	Vector2(420, -178),
	Vector2(840, -178),
	Vector2(1260, -178),
	Vector2(1500, 120),
	Vector2(1500, 760),
	Vector2(1180, 1040),
	Vector2(600, 1040),
	Vector2(0, 1040),
	Vector2(-600, 1040),
	Vector2(-1180, 1040),
	Vector2(-1500, 760),
	Vector2(-1500, 120)
])

func _ready() -> void:
	z_index = -4
	queue_redraw()

func get_route() -> PackedVector2Array:
	return route.duplicate()

func _draw() -> void:
	# Wide pavement foundation. The independent road layer sits above its centre,
	# leaving a clearly visible pedestrian strip on both sides.
	_draw_closed_path(Color(0.18, 0.10, 0.055, 0.28), 456.0)
	_draw_closed_path(Color("#625548"), 432.0)
	_draw_closed_path(Color("#b7a58d"), 410.0)
	_draw_closed_path(Color("#c8b79d"), 386.0)

	# Sparse seams make the street-walk readable without becoming realistic.
	for i in route.size():
		var point := route[i]
		var previous := route[(i - 1 + route.size()) % route.size()]
		var next := route[(i + 1) % route.size()]
		var direction := (next - previous).normalized()
		var normal := Vector2(-direction.y, direction.x)
		draw_line(point - normal * 205.0, point - normal * 150.0, Color(0.30, 0.23, 0.18, 0.20), 3.0, true)
		draw_line(point + normal * 150.0, point + normal * 205.0, Color(0.30, 0.23, 0.18, 0.20), 3.0, true)
		draw_circle(point + normal * 180.0, 4.0, Color(1.0, 0.91, 0.76, 0.18))

func get_pedestrian_route(lane_offset: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	for i in route.size():
		var previous := route[(i - 1 + route.size()) % route.size()]
		var next := route[(i + 1) % route.size()]
		var direction := (next - previous).normalized()
		var normal := Vector2(-direction.y, direction.x)
		result.append(route[i] + normal * lane_offset)
	return result

func _draw_closed_path(color: Color, width: float) -> void:
	var closed := route.duplicate()
	closed.append(route[0])
	draw_polyline(closed, color, width, true)
	# Rounded joints keep every turn looking intentionally illustrated.
	for point in route:
		draw_circle(point, width * 0.5, color)
