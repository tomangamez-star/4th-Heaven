extends Node2D

const ROAD := Color("#34373b")
const ROAD_EDGE := Color("#57585a")
const WALK := Color("#c8b79d")
const WALK_EDGE := Color("#625548")

func _ready() -> void:
	z_index = -2
	queue_redraw()

func get_extension_traffic_route() -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(1520, 345), Vector2(2020, 345), Vector2(2305, 345), Vector2(2680, 345),
		Vector2(2780, 440), Vector2(2680, 535), Vector2(2400, 535), Vector2(2400, 1280),
		Vector2(2305, 1390), Vector2(2210, 1280), Vector2(2210, 535), Vector2(1520, 535)
	])

func _draw() -> void:
	# Section two: the oval's east exit and a real four-way junction.
	_draw_road_rect(Rect2(1420, 235, 1460, 410))
	_draw_road_rect(Rect2(2100, -1120, 410, 2750))
	# Section three: a compact side-street parking court north of the junction.
	draw_style_box(_rounded(Color(0.12, 0.07, 0.04, 0.28), 42), Rect2(1810, -985, 1110, 635))
	draw_style_box(_rounded(ROAD_EDGE, 38), Rect2(1824, -971, 1082, 607))
	draw_style_box(_rounded(ROAD, 34), Rect2(1842, -953, 1046, 571))
	# Parking bays and wheel stops.
	for row in 2:
		for column in 4:
			var origin := Vector2(1935 + column * 220, -875 + row * 310)
			draw_line(origin, origin + Vector2(0, 205), Color(0.92, 0.88, 0.74, 0.58), 6.0, true)
			draw_line(origin + Vector2(170, 0), origin + Vector2(170, 205), Color(0.92, 0.88, 0.74, 0.58), 6.0, true)
			draw_line(origin + Vector2(32, 188), origin + Vector2(138, 188), Color("#77716a"), 12.0, true)
	# Short connector from the vertical road into the parking court.
	_draw_road_rect(Rect2(2210, -700, 690, 260))

func _draw_road_rect(rect: Rect2) -> void:
	draw_rect(rect.grow(205), WALK_EDGE, true)
	draw_rect(rect.grow(185), WALK, true)
	draw_rect(rect.grow(15), ROAD_EDGE, true)
	draw_rect(rect, ROAD, true)
	if rect.size.x > rect.size.y:
		draw_dashed_line(Vector2(rect.position.x, rect.get_center().y), Vector2(rect.end.x, rect.get_center().y), Color(0.96, 0.79, 0.36, 0.76), 35.0, 45.0, true)
	else:
		draw_dashed_line(Vector2(rect.get_center().x, rect.position.y), Vector2(rect.get_center().x, rect.end.y), Color(0.96, 0.79, 0.36, 0.76), 35.0, 45.0, true)

func _rounded(color: Color, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new(); box.bg_color = color; box.set_corner_radius_all(radius)
	return box
