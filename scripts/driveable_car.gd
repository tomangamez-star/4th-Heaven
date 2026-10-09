extends CharacterBody2D

const CAR_TEXTURE = preload("res://assets/vehicles/car_blue.png")
var player
var controls
var occupied := false
var speed := 0.0
var steering := 0.0
var sprite: Sprite2D
var vehicle_camera: Camera2D
var road_surface
var braking := false
var reverse_wait := 0.0
var travel_velocity := Vector2.ZERO
const WHEELBASE := 155.0
const FORWARD_SPEED := 265.0
const REVERSE_SPEED := 125.0
const ACCELERATION := 155.0
const BRAKING := 430.0

func _ready() -> void:
	name = "PlayerCar"
	z_index = 7
	add_to_group("player_vehicle")
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	safe_margin = 0.05
	sprite = Sprite2D.new(); sprite.texture = CAR_TEXTURE; sprite.scale = Vector2(0.98, 1.05); add_child(sprite)
	var collider := CollisionShape2D.new(); collider.name = "PlayerCarCollision"
	var shape := CapsuleShape2D.new(); shape.radius = 52.0; shape.height = 218.0; collider.shape = shape; add_child(collider)
	vehicle_camera = Camera2D.new(); vehicle_camera.name = "VehicleCamera"
	vehicle_camera.enabled = false
	# A hard camera lock prevents the controlled car outrunning the phone view.
	vehicle_camera.position_smoothing_enabled = false
	vehicle_camera.zoom = Vector2(1.08, 1.08)
	add_child(vehicle_camera)
	# Independent world transform: steering cannot rotate the camera offset.
	vehicle_camera.top_level = true
	vehicle_camera.ignore_rotation = true
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
	_drive(throttle, steer_input, delta)
	player.global_position = global_position
	_update_camera(delta)
	queue_redraw()

func _drive(throttle: float, steer_input: float, delta: float) -> void:
	throttle = clampf(throttle, -1.0, 1.0)
	if absf(throttle) < 0.08: throttle = 0.0
	steering = move_toward(steering, steer_input, delta * 2.6)
	var on_road: bool = not is_instance_valid(road_surface) or road_surface.is_on_road(global_position)
	var limit := FORWARD_SPEED if on_road else 110.0
	var target := throttle * (limit if throttle >= 0.0 else minf(REVERSE_SPEED,limit))
	braking = throttle * speed < -1.0
	if braking:
		speed = move_toward(speed, 0.0, BRAKING * delta)
		reverse_wait = 0.22
	elif reverse_wait > 0.0:
		reverse_wait = maxf(0.0, reverse_wait-delta)
		speed = move_toward(speed,0.0,BRAKING*delta)
	elif throttle == 0.0:
		speed = move_toward(speed,0.0,(85.0 if on_road else 180.0)*delta)
	else:
		speed = move_toward(speed,target,(ACCELERATION if on_road else 95.0)*delta)
	if absf(speed)>limit: speed=move_toward(speed,signf(speed)*limit,250.0*delta)
	var steering_angle := steering * lerpf(0.66,0.43,clampf(absf(speed)/FORWARD_SPEED,0.0,1.0))
	# Bicycle-model yaw is proportional to distance travelled, not a fixed
	# rotation command. Stationary cars cannot pivot; reverse turns naturally.
	var next_rotation := rotation + speed / WHEELBASE * tan(steering_angle) * delta
	if _can_rotate(next_rotation): rotation = next_rotation
	var forward := Vector2.UP.rotated(rotation)
	var lateral := travel_velocity - forward * travel_velocity.dot(forward)
	travel_velocity = forward * speed + lateral * exp(-(10.0 if on_road else 4.0)*delta)
	var motion := travel_velocity * delta
	# Swept motion, no post-move teleport/clamp. Recovery collisions stop the
	# drive instead of repeatedly accelerating into an overlapping obstacle.
	var collision := move_and_collide(motion, false, safe_margin, true)
	if collision:
		travel_velocity = Vector2.ZERO
		speed = 0.0
		braking = true
	velocity = travel_velocity

func _can_rotate(angle: float) -> bool:
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = $PlayerCarCollision.shape
	query.transform = Transform2D(angle,global_position)
	query.collision_mask = collision_mask
	query.exclude = [get_rid()]
	if occupied and is_instance_valid(player): query.exclude.append(player.get_rid())
	return get_world_2d().direct_space_state.intersect_shape(query,1).is_empty()

func _update_camera(delta: float) -> void:
	var look := travel_velocity * 0.13
	var target := global_position + look.limit_length(36.0)
	vehicle_camera.global_position = vehicle_camera.global_position.lerp(target,1.0-exp(-10.0*delta))
	# Bound lag, not car position. This never moves the physics body.
	vehicle_camera.global_position = global_position + (vehicle_camera.global_position-global_position).limit_length(48.0)
	vehicle_camera.force_update_scroll()

func _enter_vehicle() -> void:
	occupied = true
	speed = 0.0
	steering = 0.0
	velocity = Vector2.ZERO
	travel_velocity = Vector2.ZERO
	reverse_wait = 0.0
	visible = true
	controls.set_driving_mode(true)
	player.visible = false
	player.set_physics_process(false)
	add_collision_exception_with(player)
	player.add_collision_exception_with(self)
	for collider in player.get_children():
		if collider is CollisionShape2D: collider.set_deferred("disabled", true)
	var player_camera := player.get_node_or_null("PlayerCamera") as Camera2D
	if is_instance_valid(player_camera): player_camera.enabled = false
	vehicle_camera.enabled = true
	vehicle_camera.global_position = global_position
	vehicle_camera.make_current()
	vehicle_camera.reset_smoothing()
	vehicle_camera.force_update_scroll()

func _exit_vehicle() -> void:
	if absf(speed) > 40.0: return
	var exit_position := _find_exit()
	if exit_position == Vector2.INF: return
	occupied = false
	speed = 0.0
	steering = 0.0
	velocity = Vector2.ZERO
	travel_velocity = Vector2.ZERO
	controls.set_driving_mode(false)
	player.global_position = exit_position
	player.velocity = Vector2.ZERO
	player.visible = true
	player.set_physics_process(true)
	for collider in player.get_children():
		if collider is CollisionShape2D: collider.set_deferred("disabled", false)
	remove_collision_exception_with(player)
	player.remove_collision_exception_with(self)
	vehicle_camera.enabled = false
	var player_camera := player.get_node_or_null("PlayerCamera") as Camera2D
	if is_instance_valid(player_camera):
		player_camera.enabled = true
		player_camera.make_current()
		player_camera.reset_smoothing()
	controls.set_interact_visible(false)

func _find_exit() -> Vector2:
	var shape := CircleShape2D.new(); shape.radius=35.0
	for offset in [Vector2(115,0),Vector2(-115,0),Vector2(0,165),Vector2(0,-165)]:
		var candidate: Vector2 = global_position+offset.rotated(rotation)
		var query := PhysicsShapeQueryParameters2D.new()
		query.shape=shape; query.transform=Transform2D(0.0,candidate)
		query.exclude=[player.get_rid()]
		if get_world_2d().direct_space_state.intersect_shape(query,1).is_empty(): return candidate
	return Vector2.INF

func _draw() -> void:
	draw_style_box(_shadow_box(), Rect2(-64, -121, 128, 242))
	if occupied:
		draw_circle(Vector2.ZERO, 68.0, Color(0.15, 0.75, 0.82, 0.18), false, 4.0)

func _shadow_box() -> StyleBoxFlat:
	var box := StyleBoxFlat.new(); box.bg_color = Color(0.03, 0.025, 0.02, 0.28); box.set_corner_radius_all(22)
	return box
