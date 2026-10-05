extends CharacterBody2D

const WALK_SPEED := 205.0
const RUN_SPEED := 345.0
const ACCELERATION := 1150.0
const DECELERATION := 1450.0
const TURN_RESPONSE := 11.0

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
	var keyboard := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var touch := Vector2.ZERO
	var touch_run := false
	if is_instance_valid(controls):
		touch = controls.movement_vector
		touch_run = controls.run_pressed

	var movement_input := touch if touch.length() > 0.04 else keyboard
	input_strength = clampf(movement_input.length(), 0.0, 1.0)
	is_running = input_strength > 0.12 and (touch_run or Input.is_action_pressed("run"))
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
	visual.queue_redraw()
