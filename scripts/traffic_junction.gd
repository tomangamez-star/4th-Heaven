extends Node2D

var phase_time := 0.0
var horizontal_green := true
const CENTER := Vector2(2350, 440)

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
	# Crosswalk paint is baked into the connected PNG road chunks.
	_draw_signal(CENTER + Vector2(-255, -255), horizontal_green)
	_draw_signal(CENTER + Vector2(255, 255), horizontal_green)
	_draw_signal(CENTER + Vector2(255, -255), not horizontal_green)
	_draw_signal(CENTER + Vector2(-255, 255), not horizontal_green)

func _draw_signal(position: Vector2, green: bool) -> void:
	draw_circle(position, 22.0, Color("#252b30"))
	draw_circle(position + Vector2(-8, 0), 7.0, Color("#ea4b43") if not green else Color("#5b3331"))
	draw_circle(position + Vector2(8, 0), 7.0, Color("#55d875") if green else Color("#284c34"))
	draw_line(position, position + Vector2(0, 42), Color("#343b41"), 8.0, true)
