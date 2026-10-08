extends Node2D

var phase_time := 0.0
var horizontal_green := true
const CENTER := Vector2(2305, 440)

func _ready() -> void:
	add_to_group("traffic_signal")
	z_index = 3
	queue_redraw()

func _process(delta: float) -> void:
	phase_time += delta
	var next_horizontal := fmod(phase_time, 16.0) < 8.0
	if next_horizontal != horizontal_green:
		horizontal_green = next_horizontal
		queue_redraw()

func speed_limit_for(vehicle: Node) -> float:
	var to_center: Vector2 = CENTER - vehicle.global_position
	var forward_distance: float = vehicle.heading.dot(to_center)
	if forward_distance < 0.0 or forward_distance > 520.0: return vehicle.cruise_speed
	var moving_horizontal: bool = absf(vehicle.heading.x) > absf(vehicle.heading.y)
	if moving_horizontal == horizontal_green: return vehicle.cruise_speed
	if forward_distance < 235.0: return 0.0
	return vehicle.cruise_speed * clampf((forward_distance - 235.0) / 230.0, 0.0, 1.0)

func _draw() -> void:
	# Four bold zebra crossings around the junction.
	for offset in [-245.0, 245.0]:
		for stripe in 7:
			draw_rect(Rect2(CENTER + Vector2(offset - 36, -126 + stripe * 38), Vector2(72, 23)), Color(0.95, 0.92, 0.82, 0.78), true)
			draw_rect(Rect2(CENTER + Vector2(-126 + stripe * 38, offset - 36), Vector2(23, 72)), Color(0.95, 0.92, 0.82, 0.78), true)
	_draw_signal(CENTER + Vector2(-275, -275), horizontal_green)
	_draw_signal(CENTER + Vector2(275, 275), horizontal_green)
	_draw_signal(CENTER + Vector2(275, -275), not horizontal_green)
	_draw_signal(CENTER + Vector2(-275, 275), not horizontal_green)

func _draw_signal(position: Vector2, green: bool) -> void:
	draw_circle(position, 22.0, Color("#252b30"))
	draw_circle(position + Vector2(-8, 0), 7.0, Color("#ea4b43") if not green else Color("#5b3331"))
	draw_circle(position + Vector2(8, 0), 7.0, Color("#55d875") if green else Color("#284c34"))
	draw_line(position, position + Vector2(0, 42), Color("#343b41"), 8.0, true)
