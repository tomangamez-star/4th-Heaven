extends Node

signal time_state_changed(state_name: String)

const STATE_ORDER := ["morning", "afternoon", "evening", "night"]
const LIGHT_STATES := {
	"morning": {"tint": Color(1.0, 0.88, 0.72), "direction": Vector2(-0.72, 0.69), "length": 1.75, "strength": 0.24},
	"afternoon": {"tint": Color(1.0, 1.0, 0.96), "direction": Vector2(0.58, 0.82), "length": 1.35, "strength": 0.30},
	"evening": {"tint": Color(0.94, 0.69, 0.48), "direction": Vector2(0.82, 0.57), "length": 2.15, "strength": 0.35},
	"night": {"tint": Color(0.34, 0.43, 0.65), "direction": Vector2(-0.42, 0.91), "length": 0.82, "strength": 0.18}
}

var current_state := "afternoon"
var shadow_direction := Vector2(0.58, 0.82).normalized()
var shadow_length := 1.35
var shadow_strength := 0.30
var target_direction := shadow_direction
var target_length := shadow_length
var target_strength := shadow_strength
var target_tint := Color(1.0, 1.0, 0.96)
var canvas_tint
var transition_remaining := 0.0
var redraw_accumulator := 0.0

func _ready() -> void:
	add_to_group("world_light")
	canvas_tint = CanvasModulate.new()
	canvas_tint.name = "WorldColourGrade"
	canvas_tint.color = target_tint
	add_child(canvas_tint)
	set_process(true)

func _process(delta: float) -> void:
	if transition_remaining <= 0.0: return
	transition_remaining = maxf(0.0, transition_remaining - delta)
	var blend := 1.0 - exp(-6.5 * delta)
	shadow_direction = shadow_direction.lerp(target_direction, blend).normalized()
	shadow_length = lerpf(shadow_length, target_length, blend)
	shadow_strength = lerpf(shadow_strength, target_strength, blend)
	canvas_tint.color = canvas_tint.color.lerp(target_tint, blend)
	redraw_accumulator += delta
	if redraw_accumulator >= 0.08 or transition_remaining <= 0.0:
		redraw_accumulator = 0.0
		get_tree().call_group("world_lit_visual", "queue_redraw")

func set_time_state(state_name: String, instant: bool = false) -> void:
	if not LIGHT_STATES.has(state_name): return
	current_state = state_name
	var state: Dictionary = LIGHT_STATES[state_name]
	target_direction = (state.direction as Vector2).normalized()
	target_length = state.length
	target_strength = state.strength
	target_tint = state.tint
	if instant:
		shadow_direction = target_direction; shadow_length = target_length; shadow_strength = target_strength
		canvas_tint.color = target_tint; transition_remaining = 0.0
	else: transition_remaining = 1.25
	time_state_changed.emit(current_state)
	get_tree().call_group("world_lit_visual", "queue_redraw")

func get_shadow_offset(height: float = 10.0) -> Vector2: return shadow_direction * height * shadow_length
func get_shadow_color(alpha_scale: float = 1.0) -> Color: return Color(0.08, 0.055, 0.035, shadow_strength * alpha_scale)
func is_night() -> bool: return current_state == "night"
func get_state_index() -> int: return STATE_ORDER.find(current_state)
