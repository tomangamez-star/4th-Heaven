extends Node2D

var player

func _draw() -> void:
	if not is_instance_valid(player):
		return

	var moving: float = clampf(player.velocity.length() / 45.0, 0.0, 1.0)
	var run_blend: float = clampf((player.velocity.length() - 180.0) / 140.0, 0.0, 1.0)
	var phase: float = player.stride_phase
	var forward: Vector2 = player.display_facing
	var right: Vector2 = Vector2(-forward.y, forward.x)
	var step_wave: float = sin(phase)
	var opposite: float = sin(phase + PI)
	var cadence: float = absf(sin(phase * 2.0))
	var stop_tug: float = 4.0 * player.run_stop_amount * (1.0 - player.run_stop_amount)
	if stop_tug > 0.001:
		forward = forward.lerp(player.run_stop_forward, 0.72).normalized()
		right = Vector2(-forward.y, forward.x)

	var body_center: Vector2 = -forward * (5.0 + 4.0 * run_blend)
	var head_center: Vector2 = forward * (8.0 + 9.0 * run_blend)
	body_center += forward * stop_tug * 3.5
	head_center += forward * stop_tug * 8.5
	head_center += right * step_wave * 1.8 * moving
	var bounce: float = cadence * (1.4 + 1.8 * run_blend) * moving
	body_center -= forward * bounce * 0.25
	head_center -= forward * bounce * 0.12

	# Soft shadow is grounded independently from the bouncing body.
	draw_set_transform(Vector2(2, 10), 0.0, Vector2(1, 1))
	draw_circle(Vector2.ZERO, 30.0, Color(0.10, 0.055, 0.025, 0.26))
	draw_circle(Vector2.ZERO, 23.0, Color(0.06, 0.035, 0.02, 0.19))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	var stride: float = (8.0 + 11.0 * run_blend) * moving
	var leg_side: float = 10.0
	var left_leg: Vector2 = body_center - forward * 15.0 - right * leg_side + forward * step_wave * stride
	var right_leg: Vector2 = body_center - forward * 15.0 + right * leg_side + forward * opposite * stride
	var left_arm: Vector2 = body_center - right * 27.0 - forward * (step_wave * (5.0 + 6.0 * run_blend) * moving)
	var right_arm: Vector2 = body_center + right * 27.0 + forward * (step_wave * (5.0 + 6.0 * run_blend) * moving)

	if player.ragdoll_blend > 0.0 and player.rag_positions.size() == 6:
		var blend: float = player.ragdoll_blend
		head_center = head_center.lerp(player.rag_positions[player.PART_HEAD], blend)
		body_center = body_center.lerp(player.rag_positions[player.PART_BODY], blend)
		left_arm = left_arm.lerp(player.rag_positions[player.PART_LEFT_ARM], blend)
		right_arm = right_arm.lerp(player.rag_positions[player.PART_RIGHT_ARM], blend)
		left_leg = left_leg.lerp(player.rag_positions[player.PART_LEFT_LEG], blend)
		right_leg = right_leg.lerp(player.rag_positions[player.PART_RIGHT_LEG], blend)
		var loose_forward: Vector2 = (head_center - body_center).normalized()
		if loose_forward.length_squared() > 0.1:
			forward = forward.lerp(loose_forward, blend).normalized()
			right = Vector2(-forward.y, forward.x)

	_draw_limb(left_leg, forward, 8.0, Color("#303844"), Color("#f5eee3"))
	_draw_limb(right_leg, forward, 8.0, Color("#303844"), Color("#f5eee3"))

	# Clothing/body remains visible around the dominant head circle.
	draw_circle(body_center, 24.5, Color("#10242b"))
	draw_circle(body_center, 22.0, Color("#16a9bd"))
	draw_arc(body_center, 18.0, 0.0, TAU, 28, Color(0.57, 0.96, 1.0, 0.35), 2.0)

	_draw_arm(left_arm, right * -1.0, Color("#d99062"))
	_draw_arm(right_arm, right, Color("#d99062"))

	# Head, skin rim and directional forehead highlight.
	draw_circle(head_center, 29.5, Color("#512d20"))
	draw_circle(head_center, 27.0, Color("#d99668"))
	draw_circle(head_center + forward * 5.0, 21.5, Color("#e9ab7b"))
	draw_circle(head_center + forward * 11.0 - right * 7.0, 3.2, Color(1.0, 0.80, 0.62, 0.42))
	_draw_hair(head_center, forward, right, run_blend, step_wave)

	# Tiny direction cue: barely visible while idle, clearer with forward run posture.
	var cue_alpha: float = 0.12 + 0.12 * run_blend
	draw_arc(head_center + forward * 10.0, 7.0, forward.angle() - 0.35, forward.angle() + 0.35, 8, Color(0.20, 0.09, 0.05, cue_alpha), 1.6)

func _draw_limb(center: Vector2, forward: Vector2, radius: float, cloth: Color, shoe: Color) -> void:
	draw_circle(center, radius + 2.0, Color(0.12, 0.10, 0.10, 0.42))
	draw_circle(center, radius, cloth)
	draw_circle(center + forward * 4.0, radius * 0.58, shoe)

func _draw_arm(center: Vector2, outward: Vector2, skin: Color) -> void:
	draw_circle(center, 7.5, Color(0.14, 0.08, 0.05, 0.38))
	draw_circle(center, 6.4, skin)
	draw_circle(center + outward * 3.0, 2.0, Color(1.0, 0.77, 0.59, 0.36))

func _draw_hair(center: Vector2, forward: Vector2, right: Vector2, run_blend: float, wave: float) -> void:
	var hair: Color = Color("#15171b")
	var hair_light: Color = Color("#292b31")
	# Back mass and chunky anime tufts preserve a readable silhouette at phone scale.
	draw_circle(center - forward * 5.0, 27.2, hair)
	for i in 9:
		var side: float = (float(i) - 4.0) / 4.0
		var root: Vector2 = center + right * side * 23.0 - forward * (8.0 + absf(side) * 3.0)
		var sway: Vector2 = right * wave * (0.45 + run_blend * 0.8)
		var tip: Vector2 = root - forward * (10.0 + (1.0 - absf(side)) * 8.0) + sway
		var tangent: Vector2 = right * (5.0 - absf(side) * 1.5)
		var points: PackedVector2Array = PackedVector2Array([root - tangent, root + tangent, tip])
		draw_colored_polygon(points, hair)
	# Crown tufts.
	for side_value in [-1.0, 0.0, 1.0]:
		var side: float = float(side_value)
		var base: Vector2 = center - forward * 22.0 + right * side * 8.0
		var tip: Vector2 = base - forward * (9.0 + (1.0 - absf(side)) * 5.0) + right * side * 2.0
		draw_colored_polygon(PackedVector2Array([base - right * 5.0, base + right * 5.0, tip]), hair)
	draw_arc(center - forward * 5.0, 18.0, 0.0, TAU, 24, hair_light, 2.2)
