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
var push_target
var show_connectors := false
var clothing_color := Color("#16a9bd")
var clothing_dark := Color("#10242b")
var hair_color := Color("#15171b")
var hair_highlight := Color("#292b31")
var skin_color := Color("#e9ab7b")

func _ready() -> void:
	visual = VisualScript.new()
	visual.name = "ProceduralDoodle"
	visual.player = self
	add_child(visual)

	var collider := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 25.0
	collider.shape = shape
	add_child(collider)

func _physics_process(delta: float) -> void:
	if not is_npc and ((is_instance_valid(controls) and controls.consume_ragdoll_request()) or Input.is_action_just_pressed("ragdoll")):
		trigger_ragdoll(display_facing * 390.0)

	if ragdoll_active:
		_update_ragdoll(delta)
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
	if not is_instance_valid(push_target) or push_target.ragdoll_active:
		return false
	var direction := global_position.direction_to(push_target.global_position)
	if direction.length_squared() < 0.1:
		direction = display_facing
	facing = direction
	push_target.trigger_ragdoll(direction * 390.0)
	velocity -= direction * 35.0
	return true

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
