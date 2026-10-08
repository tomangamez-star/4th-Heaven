extends CharacterBody2D

const CAR_TEXTURE = preload("res://assets/vehicles/car_blue.png")
var player
var controls
var occupied := false
var speed := 0.0
var steering := 0.0
var sprite: Sprite2D
var vehicle_camera: Camera2D

func _ready() -> void:
	name = "PlayerCar"
	z_index = 7
	add_to_group("player_vehicle")
	sprite = Sprite2D.new(); sprite.texture = CAR_TEXTURE; sprite.scale = Vector2(0.98, 1.05); add_child(sprite)
	var collider := CollisionShape2D.new(); collider.name = "PlayerCarCollision"
	var shape := RectangleShape2D.new(); shape.size = Vector2(104, 218); collider.shape = shape; add_child(collider)
	vehicle_camera = Camera2D.new(); vehicle_camera.name = "VehicleCamera"
	vehicle_camera.enabled = false; vehicle_camera.position_smoothing_enabled = true; vehicle_camera.position_smoothing_speed = 7.5
	vehicle_camera.zoom = Vector2(1.08, 1.08)
	vehicle_camera.limit_left = -3000; vehicle_camera.limit_right = 3000
	vehicle_camera.limit_top = -2000; vehicle_camera.limit_bottom = 2000
	add_child(vehicle_camera)
	queue_redraw()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player) or not is_instance_valid(controls): return
	var nearby := global_position.distance_to(player.global_position) < 135.0
	controls.set_interact_visible(nearby or occupied)
	if controls.consume_interact_request() or Input.is_action_just_pressed("interact"):
		if occupied: _exit_vehicle()
		elif nearby: _enter_vehicle()
	if not occupied: return
	var input: Vector2 = controls.movement_vector
	if input.length() < 0.04: input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var throttle: float = -input.y
	var steer_input: float = controls.get_steering_axis()
	if absf(steer_input) < 0.01: steer_input = input.x
	steering = move_toward(steering, steer_input, delta * 3.8)
	speed = move_toward(speed, throttle * 430.0, delta * (520.0 if absf(throttle) > 0.05 else 680.0))
	if absf(speed) > 12.0:
		rotation += steering * delta * 1.75 * signf(speed)
	velocity = Vector2.UP.rotated(rotation) * speed
	move_and_slide()
	player.global_position = global_position
	queue_redraw()

func _enter_vehicle() -> void:
	occupied = true
	visible = true
	controls.set_driving_mode(true)
	player.visible = false
	player.set_physics_process(false)
	var collider: Node = player.get_node_or_null("CollisionShape2D")
	if collider: collider.set_deferred("disabled", true)
	var player_camera := player.get_node_or_null("PlayerCamera") as Camera2D
	if is_instance_valid(player_camera): player_camera.enabled = false
	vehicle_camera.enabled = true
	vehicle_camera.make_current()

func _exit_vehicle() -> void:
	occupied = false
	controls.set_driving_mode(false)
	player.global_position = global_position + Vector2.RIGHT.rotated(rotation) * 105.0
	player.visible = true
	player.set_physics_process(true)
	var collider: Node = player.get_node_or_null("CollisionShape2D")
	if collider: collider.set_deferred("disabled", false)
	vehicle_camera.enabled = false
	var player_camera := player.get_node_or_null("PlayerCamera") as Camera2D
	if is_instance_valid(player_camera):
		player_camera.enabled = true
		player_camera.make_current()
	controls.set_interact_visible(false)

func _draw() -> void:
	draw_style_box(_shadow_box(), Rect2(-64, -121, 128, 242))
	if occupied:
		draw_circle(Vector2.ZERO, 68.0, Color(0.15, 0.75, 0.82, 0.18), false, 4.0)

func _shadow_box() -> StyleBoxFlat:
	var box := StyleBoxFlat.new(); box.bg_color = Color(0.03, 0.025, 0.02, 0.28); box.set_corner_radius_all(22)
	return box
