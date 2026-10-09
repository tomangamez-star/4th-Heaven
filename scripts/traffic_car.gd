extends CharacterBody2D

const CAR_TEXTURES := [
	preload("res://assets/vehicles/car_red.png"),
	preload("res://assets/vehicles/car_blue.png"),
	preload("res://assets/vehicles/car_gold.png")
]
const BUS_TEXTURE = preload("res://assets/vehicles/city_bus.png")
const ImpactEffectScript = preload("res://scripts/vehicle_impact_effect.gd")
const WheelOverlayScript = preload("res://scripts/vehicle_wheel_overlay.gd")

var route := PackedVector2Array()
var route_index := 0
var heading := Vector2.UP
var current_speed := 0.0
var previous_speed := 0.0
var world_activity_enabled := true
var impact_cooldown := {}
var light_manager
var vehicle_kind := "car"
var color_variant := 0
var cruise_speed := 250.0
var safe_follow_distance := 150.0
var visual_root: Node2D
var sprite: Sprite2D
var travel_phase := 0.0
var impact_jolt := 0.0
var headlight: PointLight2D
var tail_light: PointLight2D
var braking := false
var wheel_overlay

func setup(kind: String, variant: int = 0) -> void:
	vehicle_kind = kind
	color_variant = posmod(variant, CAR_TEXTURES.size())
	if vehicle_kind == "bus":
		cruise_speed = 205.0
		safe_follow_distance = 205.0

func _ready() -> void:
	z_index = 6
	add_to_group("world_activity")
	add_to_group("traffic")
	add_to_group("world_lit_visual")
	var lights := get_tree().get_nodes_in_group("world_light")
	if not lights.is_empty(): light_manager = lights[0]
	visual_root = Node2D.new(); visual_root.name = "VehicleSuspension"; add_child(visual_root)
	wheel_overlay = WheelOverlayScript.new(); wheel_overlay.name = "SteeringWheels"; wheel_overlay.is_bus = vehicle_kind == "bus"; visual_root.add_child(wheel_overlay)
	sprite = Sprite2D.new(); sprite.name = "VehicleSprite"
	sprite.texture = BUS_TEXTURE if vehicle_kind == "bus" else CAR_TEXTURES[color_variant]
	# The PNGs stay readable beside the doodles: cars are roughly two doodle
	# shoulders wide, while the bus has a clearly heavier road presence.
	sprite.scale = Vector2(1.12, 1.14) if vehicle_kind == "bus" else Vector2(0.98, 1.05)
	visual_root.add_child(sprite)
	_create_collision()
	_create_vehicle_lights()
	if is_instance_valid(light_manager):
		light_manager.time_state_changed.connect(_on_time_state_changed)
		_on_time_state_changed(light_manager.current_state)
	queue_redraw()

func _create_collision() -> void:
	var body_collision := CollisionShape2D.new(); body_collision.name = "VehicleCollision"
	var body_shape := RectangleShape2D.new(); body_shape.size = Vector2(136, 370) if vehicle_kind == "bus" else Vector2(122, 226)
	body_collision.shape = body_shape; add_child(body_collision)
	var area := Area2D.new(); area.name = "ImpactArea"; area.monitoring = true; area.body_entered.connect(_on_body_entered)
	var impact_collision := CollisionShape2D.new(); var impact_shape := RectangleShape2D.new()
	impact_shape.size = body_shape.size + Vector2(10, 12); impact_collision.shape = impact_shape
	area.add_child(impact_collision); add_child(area)

func _create_vehicle_lights() -> void:
	# Beams and lamp strips are drawn from the actual bumper positions. The old
	# radial PointLights read as detached yellow/red circles beside the PNGs.
	pass

func _radial_light_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 0.92)); gradient.set_color(1, Color(1, 1, 1, 0.0))
	var texture := GradientTexture2D.new(); texture.gradient = gradient
	texture.width = 128; texture.height = 128; texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5); texture.fill_to = Vector2(1.0, 0.5)
	return texture

func _on_time_state_changed(_state_name: String) -> void:
	queue_redraw()

func configure(points: PackedVector2Array, start_index: int = 0) -> void:
	route = points.duplicate()
	if route.is_empty(): return
	route_index = posmod(start_index, route.size())
	global_position = route[route_index]
	route_index = (route_index + 1) % route.size()
	heading = global_position.direction_to(route[route_index])
	rotation = heading.angle() + PI * 0.5

func _physics_process(delta: float) -> void:
	if route.size() < 2: return
	_update_impact_cooldowns(delta)
	var target := route[route_index]
	if global_position.distance_to(target) < (70.0 if vehicle_kind == "bus" else 48.0):
		route_index = (route_index + 1) % route.size(); target = route[route_index]
	var desired := global_position.direction_to(target)
	var corner_angle := absf(heading.angle_to(desired))
	wheel_overlay.steer_angle = clampf(heading.angle_to(desired), -0.58, 0.58)
	wheel_overlay.queue_redraw()
	var corner_speed := 125.0 if vehicle_kind == "bus" else 145.0
	var target_speed := lerpf(cruise_speed, corner_speed, clampf(corner_angle / 1.10, 0.0, 1.0))
	target_speed = minf(target_speed, _traffic_speed_limit())
	target_speed = minf(target_speed, _pedestrian_speed_limit())
	for traffic_light in get_tree().get_nodes_in_group("traffic_signal"):
		if traffic_light.has_method("speed_limit_for"): target_speed = minf(target_speed, traffic_light.speed_limit_for(self))
	previous_speed = current_speed
	var acceleration := 125.0 if vehicle_kind == "bus" else 210.0
	var braking := 330.0 if vehicle_kind == "bus" else 440.0
	current_speed = move_toward(current_speed, target_speed, (acceleration if target_speed > current_speed else braking) * delta)
	self.braking = target_speed < previous_speed - 8.0 or (target_speed <= 1.0 and previous_speed > 1.0)
	impact_jolt = move_toward(impact_jolt, 0.0, delta * 4.2)
	heading = heading.lerp(desired, 1.0 - exp(-4.2 * delta)).normalized()
	velocity = heading * current_speed
	var collision := move_and_collide(velocity * delta)
	if collision:
		var normal := collision.get_normal()
		var impact := absf(velocity.dot(normal))
		velocity = velocity.slide(normal) * (0.58 if impact < current_speed * 0.70 else 0.12)
		current_speed = maxf(0.0, velocity.dot(heading))
		self.braking = true
	rotation = heading.angle() + PI * 0.5
	_update_suspension(delta, corner_angle)
	queue_redraw()

func _traffic_speed_limit() -> float:
	var nearest_gap := INF
	var lead_speed := cruise_speed
	var own_half_length := 188.0 if vehicle_kind == "bus" else 121.0
	var candidates := get_tree().get_nodes_in_group("traffic") + get_tree().get_nodes_in_group("player_vehicle")
	for candidate in candidates:
		if candidate == self or not candidate.visible: continue
		var to_other: Vector2 = candidate.global_position - global_position
		var distance := to_other.length()
		if distance < 1.0 or distance > 620.0: continue
		if heading.dot(to_other.normalized()) < 0.70: continue
		var lateral := absf(to_other.cross(heading))
		if lateral > 76.0: continue
		var candidate_heading: Vector2 = candidate.heading if candidate.is_in_group("traffic") else Vector2.UP.rotated(candidate.rotation)
		if candidate_heading.dot(heading) < 0.45: continue
		var candidate_half_length := (188.0 if candidate.vehicle_kind == "bus" else 121.0) if candidate.is_in_group("traffic") else 121.0
		var gap := distance - own_half_length - candidate_half_length
		if gap < nearest_gap:
			nearest_gap = gap
			lead_speed = candidate.current_speed if candidate.is_in_group("traffic") else absf(candidate.speed)
	if is_inf(nearest_gap): return cruise_speed
	var desired_gap := 105.0 + current_speed * 0.34
	if nearest_gap <= 42.0: return 0.0
	var gap_speed := cruise_speed * clampf((nearest_gap - 42.0) / desired_gap, 0.0, 1.0)
	return minf(gap_speed, lead_speed + maxf(0.0, nearest_gap - desired_gap) * 0.45)

func _pedestrian_speed_limit() -> float:
	var nearest := INF
	for doodle in get_tree().get_nodes_in_group("doodles"):
		if not doodle.visible or doodle.ragdoll_active: continue
		var offset: Vector2 = doodle.global_position - global_position
		var forward := heading.dot(offset)
		if forward <= 0.0 or forward > 520.0: continue
		var lateral := absf(offset.cross(heading))
		if lateral > 105.0: continue
		nearest = minf(nearest, forward)
	if is_inf(nearest): return cruise_speed
	if nearest <= 205.0: return 0.0
	return cruise_speed * clampf((nearest - 205.0) / 250.0, 0.0, 1.0)

func _update_suspension(delta: float, corner_angle: float) -> void:
	travel_phase += current_speed * delta * 0.025
	var motion_amount := clampf(current_speed / cruise_speed, 0.0, 1.0)
	var wobble := sin(travel_phase) * 0.75 * motion_amount
	var braking_amount := clampf((previous_speed - current_speed) / 8.0, 0.0, 1.0)
	visual_root.position = Vector2(cos(travel_phase * 0.53) * 0.45 + impact_jolt * 4.0, wobble - braking_amount * 1.1)
	visual_root.rotation = sin(travel_phase * 0.61) * 0.004 * motion_amount + clampf(corner_angle, -0.5, 0.5) * 0.012 + impact_jolt * 0.035

func _update_impact_cooldowns(delta: float) -> void:
	for body in impact_cooldown.keys():
		impact_cooldown[body] = float(impact_cooldown[body]) - delta
		if impact_cooldown[body] <= 0.0: impact_cooldown.erase(body)

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("doodles") or impact_cooldown.has(body): return
	impact_cooldown[body] = 1.0
	impact_jolt = 1.0
	current_speed *= 0.72
	var effect = ImpactEffectScript.new(); effect.direction = -heading
	get_parent().add_child(effect); effect.global_position = body.global_position
	if body.has_method("trigger_ragdoll"): body.trigger_ragdoll(heading * (470.0 if vehicle_kind == "bus" else 520.0))

func set_world_activity(active: bool) -> void:
	if world_activity_enabled == active: return
	world_activity_enabled = active; visible = active; set_physics_process(active)
	if not active: velocity = Vector2.ZERO

func _draw() -> void:
	var shadow_offset: Vector2 = light_manager.get_shadow_offset(12.0 if vehicle_kind == "bus" else 10.0) if is_instance_valid(light_manager) else Vector2(5, 9)
	var shadow_size := Vector2(142, 382) if vehicle_kind == "bus" else Vector2(128, 242)
	draw_set_transform(shadow_offset, 0.0, Vector2.ONE)
	draw_style_box(_shadow_box(), Rect2(-shadow_size * 0.5, shadow_size))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if is_instance_valid(light_manager) and light_manager.is_night():
		var front_y := -188.0 if vehicle_kind == "bus" else -121.0
		var width := 48.0 if vehicle_kind == "bus" else 41.0
		var far_width := 190.0 if vehicle_kind == "bus" else 158.0
		var reach := 265.0 if vehicle_kind == "bus" else 235.0
		draw_colored_polygon(PackedVector2Array([Vector2(-width, front_y), Vector2(width, front_y), Vector2(far_width, front_y - reach), Vector2(-far_width, front_y - reach)]), Color(1.0, 0.88, 0.56, 0.29))
		draw_rect(Rect2(-width-8.0,front_y-3.0,18.0,6.0),Color(1.0,0.94,0.72,0.95),true)
		draw_rect(Rect2(width-10.0,front_y-3.0,18.0,6.0),Color(1.0,0.94,0.72,0.95),true)
	# Brake lamps remain readable by day and flare strongly when traffic slows.
	var lamp_y := 188.0 if vehicle_kind == "bus" else 121.0
	var lamp_x := 48.0 if vehicle_kind == "bus" else 41.0
	var brake_color := Color(1.0, 0.08, 0.045, 1.0) if braking else Color(0.62, 0.055, 0.035, 0.82)
	draw_rect(Rect2(-lamp_x-9.0,lamp_y-3.0,18.0,6.0 if not braking else 9.0),brake_color,true)
	draw_rect(Rect2(lamp_x-9.0,lamp_y-3.0,18.0,6.0 if not braking else 9.0),brake_color,true)

func _shadow_box() -> StyleBoxFlat:
	var box := StyleBoxFlat.new(); box.bg_color = Color(0.05, 0.045, 0.04, 0.30)
	box.set_corner_radius_all(18 if vehicle_kind == "bus" else 22)
	return box
