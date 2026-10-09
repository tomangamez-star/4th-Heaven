extends CanvasLayer

var movement_vector := Vector2.ZERO
var run_pressed := false
var ragdoll_requested := false
var push_requested := false
var push_visible := false
var interact_requested := false
var interact_visible := false
var driving_mode := false
var steer_left_pressed := false
var steer_right_pressed := false
var joystick_touch := -1
var run_touch := -1
var ragdoll_touch := -1
var push_touch := -1
var interact_touch := -1
var steer_left_touch := -1
var steer_right_touch := -1
var joystick_center := Vector2.ZERO
var joystick_knob := Vector2.ZERO
var run_center := Vector2.ZERO
var ragdoll_center := Vector2.ZERO
var push_center := Vector2.ZERO
var interact_center := Vector2.ZERO
var steer_left_center := Vector2.ZERO
var steer_right_center := Vector2.ZERO
var light_manager
var time_button_centers: Array[Vector2] = []
const TIME_STATES := ["morning", "afternoon", "evening", "night"]
var viewport_size := Vector2(1280, 720)
const HudScript = preload("res://scripts/touch_hud_visual.gd")

var hud
const JOYSTICK_RADIUS := 82.0
const RUN_RADIUS := 57.0

func _ready() -> void:
	hud = HudScript.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.controls = self
	add_child(hud)
	_reflow()
	get_viewport().size_changed.connect(_reflow)

func _reflow() -> void:
	viewport_size = get_viewport().get_visible_rect().size
	joystick_center = Vector2(125, viewport_size.y - 125)
	if joystick_touch < 0:
		joystick_knob = joystick_center
	run_center = Vector2(viewport_size.x - 120, viewport_size.y - 125)
	ragdoll_center = Vector2(viewport_size.x - 120, viewport_size.y - 265)
	push_center = Vector2(viewport_size.x - 260, viewport_size.y - 125)
	interact_center = Vector2(viewport_size.x - 260, viewport_size.y - 250)
	steer_left_center = Vector2(viewport_size.x - 220, viewport_size.y - 125)
	steer_right_center = Vector2(viewport_size.x - 80, viewport_size.y - 125)
	time_button_centers.clear()
	var start_x := viewport_size.x * 0.5 - 156.0
	for i in TIME_STATES.size():
		time_button_centers.append(Vector2(start_x + float(i) * 104.0, 48.0))
	if is_instance_valid(hud):
		hud.queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			var time_index := _time_button_at(event.position)
			if time_index >= 0:
				if is_instance_valid(light_manager): light_manager.set_time_state(TIME_STATES[time_index])
			elif event.position.x < viewport_size.x * 0.48 and joystick_touch < 0:
				joystick_touch = event.index
				_update_joystick(event.position)
			elif driving_mode and event.position.distance_to(steer_left_center) <= 66.0 and steer_left_touch < 0:
				steer_left_touch = event.index
				steer_left_pressed = true
			elif driving_mode and event.position.distance_to(steer_right_center) <= 66.0 and steer_right_touch < 0:
				steer_right_touch = event.index
				steer_right_pressed = true
			elif interact_visible and event.position.distance_to(interact_center) <= RUN_RADIUS * 1.35 and interact_touch < 0:
				interact_touch = event.index
				interact_requested = true
			elif push_visible and event.position.distance_to(push_center) <= RUN_RADIUS * 1.35 and push_touch < 0:
				push_touch = event.index
				push_requested = true
			elif event.position.distance_to(ragdoll_center) <= RUN_RADIUS * 1.35 and ragdoll_touch < 0:
				ragdoll_touch = event.index
				ragdoll_requested = true
			elif event.position.distance_to(run_center) <= RUN_RADIUS * 1.55 and run_touch < 0:
				run_touch = event.index
				run_pressed = true
		else:
			if event.index == joystick_touch:
				joystick_touch = -1
				movement_vector = Vector2.ZERO
				joystick_knob = joystick_center
			if event.index == run_touch:
				run_touch = -1
				run_pressed = false
			if event.index == ragdoll_touch:
				ragdoll_touch = -1
			if event.index == push_touch:
				push_touch = -1
			if event.index == interact_touch:
				interact_touch = -1
			if event.index == steer_left_touch:
				steer_left_touch = -1
				steer_left_pressed = false
			if event.index == steer_right_touch:
				steer_right_touch = -1
				steer_right_pressed = false
		hud.queue_redraw()
	elif event is InputEventScreenDrag:
		if event.index == joystick_touch:
			_update_joystick(event.position)
			hud.queue_redraw()

func _update_joystick(position: Vector2) -> void:
	var delta := position - joystick_center
	if driving_mode:
		delta.x = 0.0
	joystick_knob = joystick_center + delta.limit_length(JOYSTICK_RADIUS)
	movement_vector = delta / JOYSTICK_RADIUS
	if movement_vector.length() > 1.0:
		movement_vector = movement_vector.normalized()

func consume_ragdoll_request() -> bool:
	if not ragdoll_requested:
		return false
	ragdoll_requested = false
	return true

func consume_push_request() -> bool:
	if not push_requested:
		return false
	push_requested = false
	return true

func set_push_visible(visible: bool) -> void:
	if push_visible == visible:
		return
	push_visible = visible
	if not visible:
		push_requested = false
	if is_instance_valid(hud):
		hud.queue_redraw()

func consume_interact_request() -> bool:
	if not interact_requested: return false
	interact_requested = false
	return true

func set_interact_visible(visible: bool) -> void:
	if interact_visible == visible: return
	interact_visible = visible
	if not visible: interact_requested = false
	if is_instance_valid(hud): hud.queue_redraw()

func set_driving_mode(enabled: bool) -> void:
	driving_mode = enabled
	# Never carry a walking touch into the car. A stale joystick vector was
	# enough to launch the vehicle before the player had touched Drive.
	movement_vector = Vector2.ZERO
	joystick_touch = -1
	joystick_knob = joystick_center
	run_pressed = false
	push_visible = false
	ragdoll_requested = false
	steer_left_pressed = false
	steer_right_pressed = false
	steer_left_touch = -1
	steer_right_touch = -1
	if is_instance_valid(hud): hud.queue_redraw()

func get_steering_axis() -> float:
	return float(steer_right_pressed) - float(steer_left_pressed)

func _time_button_at(position: Vector2) -> int:
	for i in time_button_centers.size():
		if position.distance_to(time_button_centers[i]) <= 43.0: return i
	return -1
