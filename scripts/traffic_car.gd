extends CharacterBody2D

const CAR_TEXTURES := [
	preload("res://assets/vehicles/car_red.png"),
	preload("res://assets/vehicles/car_blue.png"),
	preload("res://assets/vehicles/car_gold.png")
]
const BUS_TEXTURE = preload("res://assets/vehicles/city_bus.png")

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
	sprite = Sprite2D.new(); sprite.name = "VehicleSprite"
	sprite.texture = BUS_TEXTURE if vehicle_kind == "bus" else CAR_TEXTURES[color_variant]
	sprite.scale = Vector2(0.69, 0.69) if vehicle_kind == "bus" else Vector2(0.62, 0.62)
	visual_root.add_child(sprite)
	_create_collision()
	queue_redraw()

func _create_collision() -> void:
	var body_collision := CollisionShape2D.new(); body_collision.name = "VehicleCollision"
	var body_shape := RectangleShape2D.new(); body_shape.size = Vector2(80, 214) if vehicle_kind == "bus" else Vector2(70, 132)
	body_collision.shape = body_shape; add_child(body_collision)
	var area := Area2D.new(); area.name = "ImpactArea"; area.monitoring = true; area.body_entered.connect(_on_body_entered)
	var impact_collision := CollisionShape2D.new(); var impact_shape := RectangleShape2D.new()
	impact_shape.size = body_shape.size + Vector2(10, 12); impact_collision.shape = impact_shape
	area.add_child(impact_collision); add_child(area)

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
	var corner_speed := 125.0 if vehicle_kind == "bus" else 145.0
	var target_speed := lerpf(cruise_speed, corner_speed, clampf(corner_angle / 1.10, 0.0, 1.0))
	target_speed = minf(target_speed, _traffic_speed_limit())
	previous_speed = current_speed
	var acceleration := 125.0 if vehicle_kind == "bus" else 210.0
	var braking := 330.0 if vehicle_kind == "bus" else 440.0
	current_speed = move_toward(current_speed, target_speed, (acceleration if target_speed > current_speed else braking) * delta)
	heading = heading.lerp(desired, 1.0 - exp(-4.2 * delta)).normalized()
	velocity = heading * current_speed
	move_and_slide()
	rotation = heading.angle() + PI * 0.5
	_update_suspension(delta, corner_angle)
	queue_redraw()

func _traffic_speed_limit() -> float:
	var nearest := INF
	for candidate in get_tree().get_nodes_in_group("traffic"):
		if candidate == self or not candidate.visible: continue
		var to_other: Vector2 = candidate.global_position - global_position
		var distance := to_other.length()
		if distance < 1.0 or distance > safe_follow_distance + 150.0: continue
		if heading.dot(to_other.normalized()) < 0.70: continue
		var lateral := absf(to_other.cross(heading))
		if lateral > 62.0: continue
		if candidate.heading.dot(heading) < 0.45: continue
		nearest = minf(nearest, distance)
	if is_inf(nearest): return cruise_speed
	if nearest <= safe_follow_distance * 0.62: return 0.0
	return cruise_speed * clampf((nearest - safe_follow_distance * 0.62) / (safe_follow_distance * 0.72), 0.0, 1.0)

func _update_suspension(delta: float, corner_angle: float) -> void:
	travel_phase += current_speed * delta * 0.025
	var motion_amount := clampf(current_speed / cruise_speed, 0.0, 1.0)
	var wobble := sin(travel_phase) * 0.75 * motion_amount
	var braking_amount := clampf((previous_speed - current_speed) / 8.0, 0.0, 1.0)
	visual_root.position = Vector2(cos(travel_phase * 0.53) * 0.45, wobble - braking_amount * 1.1)
	visual_root.rotation = sin(travel_phase * 0.61) * 0.004 * motion_amount + clampf(corner_angle, -0.5, 0.5) * 0.012

func _update_impact_cooldowns(delta: float) -> void:
	for body in impact_cooldown.keys():
		impact_cooldown[body] = float(impact_cooldown[body]) - delta
		if impact_cooldown[body] <= 0.0: impact_cooldown.erase(body)

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("doodles") or impact_cooldown.has(body): return
	impact_cooldown[body] = 1.0
	if body.has_method("trigger_ragdoll"): body.trigger_ragdoll(heading * (470.0 if vehicle_kind == "bus" else 520.0))

func set_world_activity(active: bool) -> void:
	if world_activity_enabled == active: return
	world_activity_enabled = active; visible = active; set_physics_process(active)
	if not active: velocity = Vector2.ZERO

func _draw() -> void:
	var shadow_offset: Vector2 = light_manager.get_shadow_offset(12.0 if vehicle_kind == "bus" else 10.0) if is_instance_valid(light_manager) else Vector2(5, 9)
	var shadow_size := Vector2(86, 224) if vehicle_kind == "bus" else Vector2(76, 142)
	draw_set_transform(shadow_offset, 0.0, Vector2.ONE)
	draw_style_box(_shadow_box(), Rect2(-shadow_size * 0.5, shadow_size))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if is_instance_valid(light_manager) and light_manager.is_night():
		var front_y := -116.0 if vehicle_kind == "bus" else -72.0
		var width := 27.0 if vehicle_kind == "bus" else 22.0
		draw_colored_polygon(PackedVector2Array([Vector2(-width, front_y), Vector2(width, front_y), Vector2(54, front_y - 120), Vector2(-54, front_y - 120)]), Color(1.0, 0.86, 0.53, 0.13))
		draw_circle(Vector2(-width, front_y), 5.0, Color(1.0, 0.88, 0.60, 0.80))
		draw_circle(Vector2(width, front_y), 5.0, Color(1.0, 0.88, 0.60, 0.80))

func _shadow_box() -> StyleBoxFlat:
	var box := StyleBoxFlat.new(); box.bg_color = Color(0.05, 0.045, 0.04, 0.30)
	box.set_corner_radius_all(18 if vehicle_kind == "bus" else 22)
	return box
