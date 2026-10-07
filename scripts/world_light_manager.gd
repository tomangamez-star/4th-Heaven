extends Node

# v0.1.5 keeps late-afternoon light fixed while every world object begins using
# this shared source. A later clock can rotate the direction and tint globally.
var time_of_day := 16.25
var shadow_direction := Vector2(0.58, 0.82).normalized()
var shadow_strength := 0.30

func _ready() -> void:
	add_to_group("world_light")

func get_shadow_offset(height: float = 10.0) -> Vector2:
	return shadow_direction * height * 1.35

func get_shadow_color(alpha_scale: float = 1.0) -> Color:
	return Color(0.08, 0.055, 0.035, shadow_strength * alpha_scale)
