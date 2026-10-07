extends CharacterBody2D

const WALK_SPEED := 205.0
const RUN_SPEED := 345.0
const ACCELERATION := 1150.0
const DECELERATION := 1450.0
const TURN_RESPONSE := 11.0
const PART_HEAD := 0
const PART_BODY := 1
const PART_LEFT_ARM := 2
const PART_RIGHT_ARM := 3
const PART_LEFT_LEG := 4
const PART_RIGHT_LEG := 5

const VisualScript = preload("res://scripts/doodle_visual.gd")

var controls
var facing := Vector2(0, 1)
var display_facing := Vector2(0, 1)
var stride_phase := 0.0
var moved_distance := 0.0
var speed_ratio := 0.0
var is_running := false
var input_strength := 0.0
var visual
var was_running := false
var run_stop_amount := 0.0
var run_stop_forward := Vector2(0, 1)

var ragdoll_active := false
var ragdoll_recovering := false
var ragdoll_time := 0.0
var ragdoll_blend := 0.0
var rag_spin_rate := 0.0
var rag_positions: Array[Vector2] = []
var rag_velocities: Array[Vector2] = []
var is_npc := false
var home_position := Vector2.ZERO
var ai_direction := Vector2.ZERO
var ai_change_timer := 0.0
var route_points := PackedVector2Array()
var route_index := 0
var route_speed_scale := 0.58
var route_pause_time := 0.0
var route_pause_min := 0.35
var route_pause_max := 1.05
var world_activity_enabled := true
var npc_redraw_time := 0.0
var sidestep_time := 0.0
var sidestep_direction := 1.0
var player_blocked_last_frame := false
var push_target
var show_connectors := true
var clothing_color := Color("#16a9bd")
var clothing_dark := Color("#10242b")
var hair_color := Color("#15171b")
var hair_highlight := Color("#292b31")
var skin_color := Color("#e9ab7b")
var push_animation_time := 0.0
var push_pose := 0.0
var push_impact_done := false
var push_pending_target

func _ready() -> void:
	visual = VisualScript.new()
	visual.name = "ProceduralDoodle"
	visual.player = self
	add_child(visual)

	var collider := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	# Matches the visible head/limb footprint so normal doodles never overlap.
	shape.radius = 33.0
	collider.shape = shape
	add_child(collider)
	z_index = 10
	if is_npc:
		add_to_group("world_activity")

func _physics_process(delta: float) -> void:
	if not is_npc and ((is_instance_valid(controls) and controls.consume_ragdoll_request()) or Input.is_action_just_pressed("ragdoll")):
		trigger_ragdoll(display_facing * 390.0)

	if ragdoll_active:
		_update_ragdoll(delta)
		visual.queue_redraw()
		return

	if push_animation_time > 0.0:
		_update_push_animation(delta)
		visual.queue_redraw()
		return

	if is_npc:
		_update_npc(delta)
		return

	var keyboard := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var touch := Vector2.ZERO
	var touch_run := false
	if is_instance_valid(controls):
		touch = controls.movement_vector
		touch_run = controls.run_pressed

	var movement_input := touch if touch.length() > 0.04 else keyboard
	input_strength = clampf(movement_input.length(), 0.0, 1.0)
	is_running = input_strength > 0.12 and (touch_run or Input.is_action_pressed("run"))
	if was_running and input_strength < 0.08 and velocity.length() > 235.0:
		run_stop_amount = 1.0
		run_stop_forward = display_facing
	if run_stop_amount > 0.0:
		run_stop_amount = move_toward(run_stop_amount, 0.0, delta * 2.85)
	var target_speed := (RUN_SPEED if is_running else WALK_SPEED) * input_strength
	var target_velocity := movement_input.normalized() * target_speed if input_strength > 0.02 else Vector2.ZERO
	var rate := ACCELERATION if target_velocity.length() > velocity.length() else DECELERATION
	velocity = velocity.move_toward(target_velocity, rate * delta)

	if movement_input.length() > 0.08:
		facing = movement_input.normalized()
	var turn_blend := 1.0 - exp(-TURN_RESPONSE * delta)
	display_facing = display_facing.lerp(facing, turn_blend).normalized()

	var before := global_position
	move_and_slide()
	var travelled := global_position.distance_to(before)
	moved_distance += travelled
	if travelled > 0.001:
		stride_phase += travelled * (0.060 if is_running else 0.047)

	speed_ratio = clampf(velocity.length() / RUN_SPEED, 0.0, 1.0)
	was_running = is_running
	_apply_crate_pushes()
	_update_push_interaction()
	visual.queue_redraw()

func _update_npc(delta: float) -> void:
	if route_points.size() > 1:
		_update_route_npc(delta)
		return
	ai_change_timer -= delta
	if ai_change_timer <= 0.0:
		ai_change_timer = 1.35 + randf() * 1.65
		if global_position.distance_to(home_position) > 220.0:
			ai_direction = global_position.direction_to(home_position)
		elif randf() < 0.22:
			ai_direction = Vector2.ZERO
		else:
			ai_direction = Vector2.RIGHT.rotated(randf() * TAU)
	_apply_controlled_motion(ai_direction * 0.58, false, delta)
	_apply_crate_pushes()
	visual.queue_redraw()

func configure_route(points: PackedVector2Array, start_index: int, speed_scale: float, reverse: bool = false) -> void:
	route_points = points.duplicate()
	if reverse:
		route_points.reverse()
	route_index = posmod(start_index, route_points.size()) if not route_points.is_empty() else 0
	route_speed_scale = clampf(speed_scale, 0.38, 0.82)
	if not route_points.is_empty():
		global_position = route_points[route_index]
		route_index = (route_index + 1) % route_points.size()

func _update_route_npc(delta: float) -> void:
	npc_redraw_time -= delta
	sidestep_time = maxf(0.0, sidestep_time - delta)
	if route_pause_time > 0.0:
		route_pause_time -= delta
		_apply_controlled_motion(Vector2.ZERO, false, delta)
		_queue_npc_redraw()
		return
	var target := route_points[route_index]
	var distance := global_position.distance_to(target)
	if distance <= 18.0:
		route_index = (route_index + 1) % route_points.size()
		route_pause_time = randf_range(route_pause_min, route_pause_max)
		_apply_controlled_motion(Vector2.ZERO, false, delta)
		_queue_npc_redraw()
		return
	var desired := global_position.direction_to(target)
	var avoidance := Vector2.ZERO
	var blocked_ahead := false
	var player_ahead_distance := INF
	for candidate in get_tree().get_nodes_in_group("doodles"):
		if candidate == self or not candidate.visible:
			continue
		var separation: Vector2 = global_position - candidate.global_position
		var separation_length: float = separation.length()
		var awareness := 112.0 if not candidate.is_npc else 92.0
		if separation_length > 0.01 and separation_length < awareness:
			var separation_direction := separation.normalized()
			var strength := 1.0 - separation_length / awareness
			avoidance += separation_direction * strength * (1.65 if not candidate.is_npc else 1.0)
			if desired.dot(-separation_direction) > 0.55 and separation_length < 86.0:
				blocked_ahead = true
				if not candidate.is_npc:
					player_ahead_distance = minf(player_ahead_distance, separation_length)
	player_blocked_last_frame = player_ahead_distance < INF
	if blocked_ahead and sidestep_time <= 0.0:
		sidestep_time = 0.85
		sidestep_direction = -1.0 if get_instance_id() % 2 == 0 else 1.0
	# At body-contact distance pedestrians wait instead of bulldozing the player.
	# Farther away they use the same soft side-step used for another pedestrian.
	if player_ahead_distance < 72.0:
		_apply_controlled_motion(Vector2.ZERO, false, delta)
		_queue_npc_redraw()
		return
	var side := Vector2(-desired.y, desired.x) * sidestep_direction
	var sidestep := side * 0.72 if sidestep_time > 0.0 else Vector2.ZERO
	desired = (desired + avoidance * 1.15 + sidestep).normalized()
	_apply_controlled_motion(desired * route_speed_scale, false, delta)
	_apply_crate_pushes()
	_queue_npc_redraw()

func _queue_npc_redraw() -> void:
	# Procedural doodles are expensive on Web; 30 visual updates per second still
	# reads as smooth while physics and routing continue at the full tick rate.
	if npc_redraw_time > 0.0:
		return
	npc_redraw_time = 1.0 / 30.0
	visual.queue_redraw()

func set_world_activity(active: bool) -> void:
	if not is_npc or world_activity_enabled == active:
		return
	world_activity_enabled = active
	visible = active
	set_physics_process(active)
	if not active:
		velocity = Vector2.ZERO

func _apply_controlled_motion(movement_input: Vector2, wants_run: bool, delta: float) -> void:
	input_strength = clampf(movement_input.length(), 0.0, 1.0)
	is_running = input_strength > 0.12 and wants_run
	var target_speed := (RUN_SPEED if is_running else WALK_SPEED) * input_strength
	var target_velocity := movement_input.normalized() * target_speed if input_strength > 0.02 else Vector2.ZERO
	var rate := ACCELERATION if target_velocity.length() > velocity.length() else DECELERATION
	velocity = velocity.move_toward(target_velocity, rate * delta)
	if movement_input.length() > 0.08:
		facing = movement_input.normalized()
	var turn_blend := 1.0 - exp(-TURN_RESPONSE * delta)
	display_facing = display_facing.lerp(facing, turn_blend).normalized()
	var before := global_position
	move_and_slide()
	var travelled := global_position.distance_to(before)
	moved_distance += travelled
	if travelled > 0.001:
		stride_phase += travelled * (0.060 if is_running else 0.047)
	speed_ratio = clampf(velocity.length() / RUN_SPEED, 0.0, 1.0)
	was_running = is_running

func _update_push_interaction() -> void:
	push_target = null
	var closest := 112.0
	for candidate in get_tree().get_nodes_in_group("npc"):
		if candidate == self or candidate.ragdoll_active:
			continue
		var distance := global_position.distance_to(candidate.global_position)
		if distance < closest:
			closest = distance
			push_target = candidate
	if is_instance_valid(controls):
		controls.set_push_visible(push_target != null)
		if controls.consume_push_request() or Input.is_action_just_pressed("push"):
			push_nearby_npc()

func push_nearby_npc() -> bool:
	if push_animation_time > 0.0 or not is_instance_valid(push_target) or push_target.ragdoll_active:
		return false
	var direction := global_position.direction_to(push_target.global_position)
	if direction.length_squared() < 0.1:
		direction = display_facing
	facing = direction
	display_facing = direction
	push_pending_target = push_target
	push_animation_time = 0.001
	push_pose = 0.0
	push_impact_done = false
	velocity = Vector2.ZERO
	z_index = 12
	if is_instance_valid(controls):
		controls.set_push_visible(false)
	return true

func _update_push_animation(delta: float) -> void:
	push_animation_time += delta
	velocity = Vector2.ZERO
	# Extend quickly, hold contact briefly, then retract cleanly.
	if push_animation_time < 0.15:
		push_pose = clampf(push_animation_time / 0.15, 0.0, 1.0)
	elif push_animation_time < 0.23:
		push_pose = 1.0
	else:
		push_pose = clampf(1.0 - (push_animation_time - 0.23) / 0.16, 0.0, 1.0)
	if not push_impact_done and push_animation_time >= 0.16:
		push_impact_done = true
		if is_instance_valid(push_pending_target) and not push_pending_target.ragdoll_active:
			var direction := global_position.direction_to(push_pending_target.global_position)
			push_pending_target.trigger_ragdoll(direction * 390.0)
	if push_animation_time >= 0.40:
		push_animation_time = 0.0
		push_pose = 0.0
		push_impact_done = false
		push_pending_target = null
		z_index = 10

func set_connectors_enabled(enabled: bool) -> void:
	show_connectors = enabled
	if is_instance_valid(visual):
		visual.queue_redraw()

func _apply_crate_pushes() -> void:
	for index in get_slide_collision_count():
		var collision := get_slide_collision(index)
		var body := collision.get_collider()
		if body is RigidBody2D and body.is_in_group("pushable_crate"):
			var strength := 4.8 if is_running else 1.7
			body.apply_central_impulse(-collision.get_normal() * velocity.length() * strength * 0.01)

func trigger_ragdoll(impulse: Vector2) -> void:
	if ragdoll_active:
		return
	if not is_npc and is_instance_valid(controls):
		controls.set_push_visible(false)
	run_stop_amount = 0.0
	is_running = false
	was_running = false
	ragdoll_active = true
	ragdoll_recovering = false
	ragdoll_time = 0.0
	ragdoll_blend = 1.0
	rag_spin_rate = 7.5

	var forward: Vector2 = display_facing
	var right := Vector2(-forward.y, forward.x)
	var body := -forward * 5.0
	rag_positions = [
		forward * 10.0,
		body,
		body - right * 27.0,
		body + right * 27.0,
		body - forward * 17.0 - right * 10.0,
		body - forward * 17.0 + right * 10.0
	]
	rag_velocities = [
		forward * 74.0 + right * 24.0,
		-forward * 18.0,
		-right * 128.0 - forward * 30.0,
		right * 115.0 + forward * 18.0,
		-right * 52.0 - forward * 105.0,
		right * 67.0 - forward * 91.0
	]
	velocity = impulse

func _update_ragdoll(delta: float) -> void:
	ragdoll_time += delta
	velocity = velocity.move_toward(Vector2.ZERO, 245.0 * delta)
	move_and_slide()
	display_facing = display_facing.rotated(rag_spin_rate * delta).normalized()
	rag_spin_rate = move_toward(rag_spin_rate, 0.0, 4.2 * delta)

	if not ragdoll_recovering:
		for i in rag_positions.size():
			var swirl := Vector2(-rag_positions[i].y, rag_positions[i].x) * rag_spin_rate * 0.08
			rag_velocities[i] += swirl * delta
			rag_positions[i] += rag_velocities[i] * delta
			rag_velocities[i] *= exp(-3.0 * delta)
		_apply_spring(PART_BODY, PART_HEAD, 22.0, 31.0, delta)
		_apply_spring(PART_BODY, PART_LEFT_ARM, 28.0, 27.0, delta)
		_apply_spring(PART_BODY, PART_RIGHT_ARM, 28.0, 27.0, delta)
		_apply_spring(PART_BODY, PART_LEFT_LEG, 29.0, 25.0, delta)
		_apply_spring(PART_BODY, PART_RIGHT_LEG, 29.0, 25.0, delta)
		# Keeps the loose body centred on the moving collision body.
		rag_velocities[PART_BODY] += -rag_positions[PART_BODY] * 13.0 * delta
		if (ragdoll_time >= 1.55 and velocity.length() < 95.0) or ragdoll_time >= 2.10:
			ragdoll_recovering = true
	else:
		var targets := _standing_part_positions()
		for i in rag_positions.size():
			rag_positions[i] = rag_positions[i].lerp(targets[i], 1.0 - exp(-8.5 * delta))
			rag_velocities[i] = Vector2.ZERO
		ragdoll_blend = move_toward(ragdoll_blend, 0.0, delta * 1.65)
		if ragdoll_blend <= 0.001:
			ragdoll_active = false
			ragdoll_recovering = false
			ragdoll_blend = 0.0
			ragdoll_time = 0.0

func _apply_spring(a: int, b: int, rest_length: float, strength: float, delta: float) -> void:
	var difference := rag_positions[b] - rag_positions[a]
	var distance := maxf(difference.length(), 0.001)
	var direction := difference / distance
	var force := direction * (distance - rest_length) * strength * delta
	rag_velocities[a] += force
	rag_velocities[b] -= force

func _standing_part_positions() -> Array[Vector2]:
	var forward: Vector2 = display_facing
	var right := Vector2(-forward.y, forward.x)
	var body := -forward * 5.0
	return [
		forward * 10.0,
		body,
		body - right * 27.0,
		body + right * 27.0,
		body - forward * 17.0 - right * 10.0,
		body - forward * 17.0 + right * 10.0
	]
