extends Node2D

var phase_time := 0.0
var horizontal_green := true
const CENTER := Vector2(2350, 440)
const SIGNAL_RED = preload("res://assets/environment/traffic_signal_red.png")
const SIGNAL_GREEN = preload("res://assets/environment/traffic_signal_green.png")
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
	# Each mast belongs to one incoming approach. Arms extend squarely over its
	# lane instead of all four pointing diagonally at the junction centre.
	var positions := [CENTER + Vector2(-300, -245), CENTER + Vector2(300, 245), CENTER + Vector2(245, -300), CENTER + Vector2(-245, 300)]
	var directions := [Vector2.DOWN, Vector2.UP, Vector2.LEFT, Vector2.RIGHT]
	var horizontal := [true, true, false, false]
	var overlay := Node2D.new(); overlay.name = "TrafficSignalArtOverlay"
	overlay.z_as_relative = false; overlay.z_index = 15; add_child(overlay)
	var collisions := Node2D.new(); collisions.name = "TrafficSignalBases"; add_child(collisions)
	for i in positions.size():
		var position: Vector2 = positions[i]
		var direction: Vector2 = directions[i]
		var sprite := Sprite2D.new(); sprite.texture = SIGNAL_RED; sprite.centered = false
		sprite.offset = Vector2(-22, -38); sprite.position = position; sprite.rotation = direction.angle()
		overlay.add_child(sprite); signal_heads.append(sprite); signal_green.append(horizontal[i])
		var body := StaticBody2D.new(); body.position = position; body.name = "TrafficSignalPole"
		var collision := CollisionShape2D.new(); var shape := CircleShape2D.new(); shape.radius = 18.0
		collision.shape = shape; body.add_child(collision); collisions.add_child(body)
	_update_signal_tints()

func _update_signal_tints() -> void:
	for i in signal_heads.size():
		var green := horizontal_green if signal_green[i] else not horizontal_green
		signal_heads[i].texture = SIGNAL_GREEN if green else SIGNAL_RED
