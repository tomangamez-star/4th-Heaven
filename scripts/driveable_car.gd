extends CharacterBody2D

const CAR_TEXTURE = preload("res://assets/vehicles/car_blue.png")
const WheelOverlayScript = preload("res://scripts/vehicle_wheel_overlay.gd")
var player
var controls
var occupied := false
var speed := 0.0
var steering := 0.0
var sprite: Sprite2D
var wheel_overlay
var vehicle_camera: Camera2D
var road_surface
var braking := false
var reverse_wait := 0.0
var travel_velocity := Vector2.ZERO
var light_manager
var headlight: PointLight2D
var camera_target_rotation := 0.0
var camera_turn_hold := 0.0
var camera_following_turn := false
var camera_settle_hold := 0.0
var camera_transition := ""
var camera_transition_time := 0.0
var camera_transition_start_position := Vector2.ZERO
var camera_transition_start_rotation := 0.0
var camera_transition_start_zoom := Vector2.ONE
const WHEELBASE := 155.0
const FORWARD_SPEED := 265.0
const REVERSE_SPEED := 125.0
const ACCELERATION := 155.0
const BRAKING := 430.0

func _ready() -> void:
	name = "PlayerCar"
	z_index = 7
	add_to_group("player_vehicle")
	var lights := get_tree().get_nodes_in_group("world_light")
	if not lights.is_empty(): light_manager = lights[0]
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	safe_margin = 0.05
	wheel_overlay = WheelOverlayScript.new(); wheel_overlay.name = "SteeringWheels"; add_child(wheel_overlay)
	sprite = Sprite2D.new(); sprite.texture = CAR_TEXTURE; sprite.scale = Vector2(0.98, 1.05); add_child(sprite)
	_create_headlight()
	var collider := CollisionShape2D.new(); collider.name = "PlayerCarCollision"
	var shape := CapsuleShape2D.new(); shape.radius = 62.0; shape.height = 232.0; collider.shape = shape; add_child(collider)
	vehicle_camera = Camera2D.new(); vehicle_camera.name = "VehicleCamera"
	vehicle_camera.enabled = false
	# A hard camera lock prevents the controlled car outrunning the phone view.
	vehicle_camera.position_smoothing_enabled = false
	vehicle_camera.zoom = Vector2(1.08, 1.08)
	add_child(vehicle_camera)
	# Independent world transform: steering cannot rotate the camera offset.
	vehicle_camera.top_level = true
	vehicle_camera.ignore_rotation = false
	queue_redraw()

func _create_headlight() -> void:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 0.94)); gradient.add_point(0.35, Color(1, 0.84, 0.50, 0.60)); gradient.set_color(1, Color(1, 1, 1, 0))
	var texture := GradientTexture2D.new(); texture.gradient = gradient; texture.width = 420; texture.height = 420
	texture.fill = GradientTexture2D.FILL_RADIAL; texture.fill_from = Vector2(0.5, 0.5); texture.fill_to = Vector2(1, 0.5)
	headlight = PointLight2D.new(); headlight.name = "PlayerCarWorldHeadlight"
	headlight.position = Vector2(0, -205); headlight.texture = texture; headlight.texture_scale = 1.35
	headlight.energy = 1.15; headlight.color = Color("#ffe0a0"); headlight.add_to_group("vehicle_world_headlight"); add_child(headlight)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player) or not is_instance_valid(controls): return
	if is_instance_valid(headlight): headlight.enabled = is_instance_valid(light_manager) and light_manager.is_night()
	if camera_transition != "":
		_update_camera_transition(delta)
		return
	var nearby := global_position.distance_to(player.global_position) < 135.0
	controls.set_interact_visible(nearby or occupied)
	if controls.consume_interact_request() or Input.is_action_just_pressed("interact"):
		if occupied: _exit_vehicle()
		elif nearby: _enter_vehicle()
	if not occupied: return
	var keyboard := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var throttle: float = controls.get_drive_throttle()
	if absf(throttle) < 0.01: throttle = -keyboard.y
	var steer_input: float = controls.get_steering_axis()
	if absf(steer_input) < 0.01: steer_input = keyboard.x
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
	wheel_overlay.steer_angle = steering_angle * 0.82
	wheel_overlay.queue_redraw()
	# Kinematic axle model: the rear axle follows the body while the front axle
	# moves in its steered direction. The nose now pulls the car through an arc
	# instead of rotating the whole sprite around its centre.
	var forward := Vector2.UP.rotated(rotation)
	var rear_axle := global_position - forward * WHEELBASE * 0.5
	var front_axle := global_position + forward * WHEELBASE * 0.5
	rear_axle += forward * speed * delta
	front_axle += Vector2.UP.rotated(rotation + steering_angle) * speed * delta
	var axle_heading := rear_axle.direction_to(front_axle)
	var next_rotation := axle_heading.angle() + PI * 0.5
	if _can_rotate(next_rotation): rotation = next_rotation
	forward = Vector2.UP.rotated(rotation)
	var lateral := travel_velocity - forward * travel_velocity.dot(forward)
	travel_velocity = forward * speed + lateral * exp(-(10.0 if on_road else 4.0)*delta)
	var motion := travel_velocity * delta
	# Swept motion, no post-move teleport/clamp. Recovery collisions stop the
	# drive instead of repeatedly accelerating into an overlapping obstacle.
	var collision := move_and_collide(motion, false, safe_margin, true)
	if collision:
		var normal := collision.get_normal()
		var impact := absf(travel_velocity.dot(normal))
		travel_velocity = travel_velocity.slide(normal) * (0.62 if impact < absf(speed) * 0.72 else 0.18)
		speed = travel_velocity.dot(forward)
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
	var desired_rotation := rotation
	var visible_heading_error := absf(wrapf(desired_rotation - vehicle_camera.global_rotation, -PI, PI))
	# A turn has two states. The camera initially holds so small steering inputs do
	# not twitch the world. Once the car has visibly changed heading for a moment,
	# follow is latched and the target is refreshed every frame. This avoids the old
	# 27-degree target snapshots that produced rotate-stop-rotate camera motion.
	if not camera_following_turn:
		if absf(speed) > 38.0 and visible_heading_error > deg_to_rad(8.0):
			camera_turn_hold += delta
			if camera_turn_hold >= 0.16:
				camera_following_turn = true
				camera_settle_hold = 0.0
		else:
			camera_turn_hold = maxf(0.0, camera_turn_hold - delta * 3.0)
	if camera_following_turn:
		camera_target_rotation = desired_rotation
		var settled := visible_heading_error < deg_to_rad(3.5) and absf(steering) < 0.10
		camera_settle_hold = camera_settle_hold + delta if settled else 0.0
		if camera_settle_hold >= 0.32 or absf(speed) < 18.0:
			camera_following_turn = false
			camera_turn_hold = 0.0
			camera_settle_hold = 0.0
	var camera_error := wrapf(camera_target_rotation - vehicle_camera.global_rotation, -PI, PI)
	var max_step := deg_to_rad(48.0) * delta
	vehicle_camera.global_rotation += clampf(camera_error * (1.0 - exp(-1.75 * delta)), -max_step, max_step)
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
	vehicle_camera.global_position = player.global_position
	vehicle_camera.global_rotation = 0.0
	camera_target_rotation = rotation
	camera_following_turn = false
	camera_turn_hold = 0.0
	camera_settle_hold = 0.0
	vehicle_camera.zoom = player_camera.zoom if is_instance_valid(player_camera) else Vector2(1.08, 1.08)
	vehicle_camera.make_current()
	vehicle_camera.reset_smoothing()
	vehicle_camera.force_update_scroll()
	_begin_camera_transition("enter")

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
	player.set_physics_process(false)
	for collider in player.get_children():
		if collider is CollisionShape2D: collider.set_deferred("disabled", false)
	remove_collision_exception_with(player)
	player.remove_collision_exception_with(self)
	var player_camera := player.get_node_or_null("PlayerCamera") as Camera2D
	if is_instance_valid(player_camera): player_camera.enabled = false
	_begin_camera_transition("exit")
	controls.set_interact_visible(false)

func _begin_camera_transition(kind: String) -> void:
	camera_transition = kind
	camera_transition_time = 0.0
	camera_transition_start_position = vehicle_camera.global_position
	camera_transition_start_rotation = vehicle_camera.global_rotation
	camera_transition_start_zoom = vehicle_camera.zoom

func _update_camera_transition(delta: float) -> void:
	if camera_transition == "": return
	camera_transition_time += delta
	var amount := clampf(camera_transition_time / 0.62, 0.0, 1.0)
	var eased := amount * amount * (3.0 - 2.0 * amount)
	var target_position: Vector2 = global_position if camera_transition == "enter" else player.global_position
	var target_rotation: float = rotation if camera_transition == "enter" else 0.0
	var player_camera := player.get_node_or_null("PlayerCamera") as Camera2D
	var target_zoom: Vector2 = Vector2(1.08, 1.08) if camera_transition == "enter" else (player_camera.zoom if is_instance_valid(player_camera) else Vector2(1.08, 1.08))
	vehicle_camera.global_position = camera_transition_start_position.lerp(target_position, eased)
	vehicle_camera.global_rotation = lerp_angle(camera_transition_start_rotation, target_rotation, eased)
	vehicle_camera.zoom = camera_transition_start_zoom.lerp(target_zoom, eased)
	vehicle_camera.force_update_scroll()
	if amount < 1.0: return
	var completed := camera_transition
	camera_transition = ""
	if completed == "enter":
		camera_target_rotation = vehicle_camera.global_rotation
		camera_following_turn = false
		camera_turn_hold = 0.0
		camera_settle_hold = 0.0
	else:
		vehicle_camera.enabled = false
		player.set_physics_process(true)
		if is_instance_valid(player_camera):
			player_camera.enabled = true
			player_camera.make_current()
			player_camera.reset_smoothing()

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
	if is_instance_valid(light_manager) and light_manager.is_night():
		draw_colored_polygon(PackedVector2Array([Vector2(-42,-116),Vector2(42,-116),Vector2(150,-345),Vector2(-150,-345)]),Color(1.0,0.88,0.58,0.25))
		draw_rect(Rect2(-47,-121,18,6),Color(1.0,0.94,0.72,0.92),true)
		draw_rect(Rect2(29,-121,18,6),Color(1.0,0.94,0.72,0.92),true)
	var brake_color := Color(1.0,0.08,0.04,0.96) if braking else Color(0.50,0.035,0.025,0.72)
	draw_rect(Rect2(-48,115,18,6),brake_color,true)
	draw_rect(Rect2(30,115,18,6),brake_color,true)
	if occupied:
		draw_circle(Vector2.ZERO, 68.0, Color(0.15, 0.75, 0.82, 0.18), false, 4.0)

func _shadow_box() -> StyleBoxFlat:
	var box := StyleBoxFlat.new(); box.bg_color = Color(0.03, 0.025, 0.02, 0.28); box.set_corner_radius_all(22)
	return box
