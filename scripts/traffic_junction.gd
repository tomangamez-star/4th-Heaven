extends Node2D

var phase_time := 0.0
var horizontal_green := true
const CENTER := Vector2(2350, 440)
const SIGNAL_TEXTURE = preload("res://assets/environment/traffic_signal_top.png")
var signal_heads: Array[Sprite2D] = []
var signal_green: Array[bool] = []

func _ready() -> void:
	add_to_group("traffic_signal")
	z_index = 3
	_create_signals()
	queue_redraw()

func _process(delta: float) -> void:
	phase_time += delta
	var next_horizontal := fmod(phase_time, 16.0) < 8.0
	if next_horizontal != horizontal_green:
		horizontal_green = next_horizontal
		_update_signal_tints()
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
	pass

func _create_signals() -> void:
	var positions := [CENTER + Vector2(-255, -255), CENTER + Vector2(255, 255), CENTER + Vector2(255, -255), CENTER + Vector2(-255, 255)]
	var horizontal := [true, true, false, false]
	var overlay := Node2D.new(); overlay.name = "TrafficSignalArtOverlay"
	overlay.z_as_relative = false; overlay.z_index = 15; add_child(overlay)
	var collisions := Node2D.new(); collisions.name = "TrafficSignalBases"; add_child(collisions)
	for i in positions.size():
		var position: Vector2 = positions[i]
		var direction := position.direction_to(CENTER)
		var sprite := Sprite2D.new(); sprite.texture = SIGNAL_TEXTURE; sprite.centered = false
		sprite.offset = Vector2(-22, -38); sprite.position = position; sprite.rotation = direction.angle()
		overlay.add_child(sprite); signal_heads.append(sprite); signal_green.append(horizontal[i])
		var body := StaticBody2D.new(); body.position = position; body.name = "TrafficSignalPole"
		var collision := CollisionShape2D.new(); var shape := CircleShape2D.new(); shape.radius = 18.0
		collision.shape = shape; body.add_child(collision); collisions.add_child(body)
	_update_signal_tints()

func _update_signal_tints() -> void:
	for i in signal_heads.size():
		var green := horizontal_green if signal_green[i] else not horizontal_green
		signal_heads[i].modulate = Color(0.88, 1.0, 0.89) if green else Color(1.0, 0.86, 0.84)
