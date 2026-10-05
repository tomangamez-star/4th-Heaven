extends StaticBody2D

const WALL_SIZE := Vector2(390, 74)

func _ready() -> void:
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = WALL_SIZE
	collision.shape = shape
	add_child(collision)
	queue_redraw()

func _draw() -> void:
	# Grounded shadow and warm, deliberately imperfect doodle bricks.
	draw_rect(Rect2(-WALL_SIZE.x * 0.5 + 7, -WALL_SIZE.y * 0.5 + 10, WALL_SIZE.x, WALL_SIZE.y), Color(0.12, 0.065, 0.035, 0.24), true)
	draw_rect(Rect2(-WALL_SIZE.x * 0.5, -WALL_SIZE.y * 0.5, WALL_SIZE.x, WALL_SIZE.y), Color("#7b3f2d"), true)
	var brick_w := 62.0
	var brick_h := 31.0
	for row in 2:
		var offset := -brick_w * 0.5 if row % 2 == 1 else 0.0
		for column in 8:
			var x := -WALL_SIZE.x * 0.5 + float(column) * brick_w + offset
			var rect := Rect2(x + 3, -WALL_SIZE.y * 0.5 + 5 + float(row) * brick_h, brick_w - 6, brick_h - 5)
			var shade := Color("#a95d43") if (column + row) % 3 else Color("#944b38")
			draw_rect(rect, shade, true)
			draw_line(rect.position + Vector2(5, rect.size.y - 3), rect.end - Vector2(5, 3), Color(0.23, 0.10, 0.065, 0.24), 2.0)
	draw_line(Vector2(-WALL_SIZE.x * 0.5, -WALL_SIZE.y * 0.5), Vector2(WALL_SIZE.x * 0.5, -WALL_SIZE.y * 0.5), Color(1.0, 0.66, 0.47, 0.24), 3.0)
	draw_line(Vector2(-46, -18), Vector2(-34, -5), Color(0.20, 0.08, 0.05, 0.34), 3.0)
	draw_line(Vector2(-34, -5), Vector2(-41, 9), Color(0.20, 0.08, 0.05, 0.34), 3.0)

