extends Node2D

var route := PackedVector2Array()

func configure(points: PackedVector2Array) -> void:
	route = points.duplicate()
	z_index = -3
	queue_redraw()

func get_vehicle_route(lane_offset: float = -95.0) -> PackedVector2Array:
	var result := PackedVector2Array()
	for i in route.size():
		var previous := route[(i - 1 + route.size()) % route.size()]
		var next := route[(i + 1) % route.size()]
		var direction := (next - previous).normalized()
		var normal := Vector2(-direction.y, direction.x)
		result.append(route[i] + normal * lane_offset)
	return result

func _draw() -> void:
	if route.size() < 2:
		return
	# Two generous lanes keep cars visually larger than pedestrians without
	# making either lane feel cramped.
	_draw_closed_path(Color(0.12, 0.07, 0.04, 0.30), 430.0)
	_draw_closed_path(Color("#57585a"), 410.0)
	_draw_closed_path(Color("#34373b"), 380.0)
	_draw_closed_path(Color(1.0, 0.78, 0.31, 0.72), 5.0)
	# Short hand-painted lane markings keep the road readable at phone scale.
	for i in route.size():
		var a := route[i]
		var b := route[(i + 1) % route.size()]
		var segment := b - a
		var length := segment.length()
		var direction := segment.normalized()
		var count := int(length / 105.0)
		for dash in count:
			var center := a + direction * (float(dash) + 0.5) * length / float(maxi(count, 1))
			draw_line(center - direction * 22.0, center + direction * 22.0, Color(0.96, 0.89, 0.74, 0.62), 5.0, true)

func _draw_closed_path(color: Color, width: float) -> void:
	var closed := route.duplicate()
	closed.append(route[0])
	draw_polyline(closed, color, width, true)
	for point in route:
		draw_circle(point, width * 0.5, color)
