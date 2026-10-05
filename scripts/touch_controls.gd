extends CanvasLayer

var movement_vector := Vector2.ZERO
var run_pressed := false
var ragdoll_requested := false
var push_requested := false
var push_visible := false
var connectors_enabled := false
var joystick_touch := -1
var run_touch := -1
var ragdoll_touch := -1
var push_touch := -1
var toggle_touch := -1
var joystick_center := Vector2.ZERO
var joystick_knob := Vector2.ZERO
var run_center := Vector2.ZERO
var ragdoll_center := Vector2.ZERO
var push_center := Vector2.ZERO
var toggle_center := Vector2.ZERO
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
	toggle_center = Vector2(viewport_size.x - 74, 68)
	if is_instance_valid(hud):
		hud.queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.x < viewport_size.x * 0.48 and joystick_touch < 0:
				joystick_touch = event.index
				_update_joystick(event.position)
			elif event.position.distance_to(toggle_center) <= 52.0 and toggle_touch < 0:
				toggle_touch = event.index
				connectors_enabled = not connectors_enabled
				get_tree().call_group("doodles", "set_connectors_enabled", connectors_enabled)
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
			if event.index == toggle_touch:
				toggle_touch = -1
		hud.queue_redraw()
	elif event is InputEventScreenDrag:
		if event.index == joystick_touch:
			_update_joystick(event.position)
			hud.queue_redraw()

func _update_joystick(position: Vector2) -> void:
	var delta := position - joystick_center
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
