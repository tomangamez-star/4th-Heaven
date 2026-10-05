extends Node2D

const CRUISE_SPEED := 250.0

var route := PackedVector2Array()
var route_index := 0
var heading := Vector2.RIGHT
var current_speed := 0.0
var world_activity_enabled := true
var impact_cooldown := {}

func _ready() -> void:
	z_index = 6
	add_to_group("world_activity")
	var area := Area2D.new()
	area.name = "ImpactArea"
	area.monitoring = true
	area.body_entered.connect(_on_body_entered)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(82, 142)
	collision.shape = shape
	area.add_child(collision)
	add_child(area)
	queue_redraw()

func configure(points: PackedVector2Array, start_index: int = 0) -> void:
	route = points.duplicate()
	if route.is_empty():
		return
	route_index = posmod(start_index, route.size())
	global_position = route[route_index]
	route_index = (route_index + 1) % route.size()
	heading = global_position.direction_to(route[route_index])
	rotation = heading.angle() + PI * 0.5

func _physics_process(delta: float) -> void:
	if route.size() < 2:
		return
	for body in impact_cooldown.keys():
		impact_cooldown[body] = float(impact_cooldown[body]) - delta
		if impact_cooldown[body] <= 0.0:
			impact_cooldown.erase(body)
	var target := route[route_index]
	if global_position.distance_to(target) < 52.0:
		route_index = (route_index + 1) % route.size()
		target = route[route_index]
	var desired := global_position.direction_to(target)
	var corner_angle := absf(heading.angle_to(desired))
	var target_speed := lerpf(CRUISE_SPEED, 145.0, clampf(corner_angle / 1.15, 0.0, 1.0))
	current_speed = move_toward(current_speed, target_speed, 210.0 * delta)
	heading = heading.lerp(desired, 1.0 - exp(-4.8 * delta)).normalized()
	global_position += heading * current_speed * delta
	rotation = heading.angle() + PI * 0.5

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("doodles") or impact_cooldown.has(body):
		return
	impact_cooldown[body] = 1.0
	if body.has_method("trigger_ragdoll"):
		body.trigger_ragdoll(heading * 520.0)

func set_world_activity(active: bool) -> void:
	if world_activity_enabled == active:
		return
	world_activity_enabled = active
	visible = active
	set_physics_process(active)

func _draw() -> void:
	# Car faces upward locally; the node rotates along its authored road route.
	draw_set_transform(Vector2(5, 9), 0.0, Vector2.ONE)
	draw_rect(Rect2(-38, -67, 76, 134), Color(0.06, 0.05, 0.05, 0.30), true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for y in [-44.0, 42.0]:
		draw_rect(Rect2(-45, y - 15, 10, 30), Color("#17191c"), true)
		draw_rect(Rect2(35, y - 15, 10, 30), Color("#17191c"), true)
	draw_rect(Rect2(-39, -70, 78, 140), Color("#762f2d"), true)
	draw_rect(Rect2(-34, -65, 68, 130), Color("#c84c46"), true)
	draw_colored_polygon(PackedVector2Array([Vector2(-28, -39), Vector2(28, -39), Vector2(23, -10), Vector2(-23, -10)]), Color("#263b4a"))
	draw_colored_polygon(PackedVector2Array([Vector2(-23, 5), Vector2(23, 5), Vector2(28, 36), Vector2(-28, 36)]), Color("#1e313d"))
	draw_line(Vector2(0, -63), Vector2(0, 61), Color(1.0, 0.58, 0.49, 0.32), 3.0)
	draw_circle(Vector2(-25, -59), 6.0, Color("#ffe5a3"))
	draw_circle(Vector2(25, -59), 6.0, Color("#ffe5a3"))
	draw_circle(Vector2(-25, 59), 5.0, Color("#9d191d"))
	draw_circle(Vector2(25, 59), 5.0, Color("#9d191d"))
	draw_rect(Rect2(-39, -70, 78, 140), Color(1.0, 0.73, 0.61, 0.25), false, 3.0)
