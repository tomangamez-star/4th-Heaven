extends Node2D

var pebbles: Array[Dictionary] = []

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4042026
	for i in 520:
		pebbles.append({
			"p": Vector2(rng.randf_range(-2900, 2900), rng.randf_range(-1900, 1900)),
			"r": rng.randf_range(2.0, 7.0),
			"a": rng.randf_range(0.05, 0.15)
		})
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-3000, -2000, 6000, 4000), Color("#a97843"), true)
	# Broad patches stop the test ground from feeling like a blank debug screen.
	for x in range(-2900, 2901, 180):
		for y in range(-1900, 1901, 180):
			var n := sin(float(x) * 0.013 + float(y) * 0.009)
			var tint := Color(0.25, 0.13, 0.055, 0.028 if n > 0.0 else 0.018)
			draw_circle(Vector2(x, y), 100.0 + abs(n) * 35.0, tint)
	for stone in pebbles:
		var c := Color(0.20, 0.12, 0.07, stone.a)
		draw_circle(stone.p, stone.r, c)
	# A subtle origin marker makes speed, stopping and camera drift easier to judge.
	draw_circle(Vector2.ZERO, 170.0, Color(0.22, 0.12, 0.055, 0.12), false, 3.0)
	draw_line(Vector2(-210, 0), Vector2(210, 0), Color(1, 0.88, 0.64, 0.13), 2.0)
	draw_line(Vector2(0, -210), Vector2(0, 210), Color(1, 0.88, 0.64, 0.13), 2.0)
