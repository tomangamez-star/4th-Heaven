extends RigidBody2D

const CRATE_SIZE := Vector2(72, 72)

func _ready() -> void:
	add_to_group("pushable_crate")
	z_index = 3
	mass = 2.7
	gravity_scale = 0.0
	linear_damp = 3.8
	angular_damp = 5.5
	contact_monitor = true
	max_contacts_reported = 6
	var material := PhysicsMaterial.new()
	material.friction = 0.72
	material.bounce = 0.08
	physics_material_override = material
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = CRATE_SIZE
	collision.shape = shape
	add_child(collision)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-31, -29, 72, 72), Color(0.12, 0.065, 0.025, 0.25), true)
	draw_rect(Rect2(-36, -36, 72, 72), Color("#6d3f21"), true)
	draw_rect(Rect2(-31, -31, 62, 62), Color("#b8773e"), true)
	for y in [-20.0, 0.0, 20.0]:
		draw_line(Vector2(-29, y), Vector2(29, y), Color(0.30, 0.14, 0.055, 0.36), 3.0)
	draw_line(Vector2(-27, -27), Vector2(27, 27), Color("#7e4a28"), 8.0, true)
	draw_line(Vector2(27, -27), Vector2(-27, 27), Color("#7e4a28"), 8.0, true)
	draw_rect(Rect2(-34, -34, 68, 68), Color(1.0, 0.76, 0.45, 0.28), false, 3.0)
	draw_circle(Vector2(-17, -15), 3.2, Color(1.0, 0.82, 0.56, 0.25))
	draw_line(Vector2(8, 19), Vector2(19, 16), Color(0.25, 0.11, 0.04, 0.35), 2.0)
