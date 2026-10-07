extends Node2D

const ShelterRoofScript = preload("res://scripts/shelter_roof_overlay.gd")
const ROAD_HALF_WIDTH := 190.0
const FURNITURE_OFFSET := 430.0

var light_manager
var route := PackedVector2Array()
var bench_spots := PackedVector2Array()
var bus_stop_spots := PackedVector2Array()
var gather_spots := PackedVector2Array()
var streetlight_spots := PackedVector2Array()
var bin_spots := PackedVector2Array()
var sign_spots := PackedVector2Array()
var prop_rotations: Dictionary = {}

func configure(points: PackedVector2Array) -> void:
	route = points.duplicate()
	_rebuild_layout()

func _ready() -> void:
	z_index = 4
	add_to_group("street_furniture")
	var lights := get_tree().get_nodes_in_group("world_light")
	if not lights.is_empty(): light_manager = lights[0]
	_create_collisions()
	_create_shelter_roofs()
	queue_redraw()

func _rebuild_layout() -> void:
	bench_spots.clear(); bus_stop_spots.clear(); gather_spots.clear()
	streetlight_spots.clear(); bin_spots.clear(); sign_spots.clear(); prop_rotations.clear()
	if route.size() < 8: return
	# Sparse, deliberate furniture beyond both pedestrian lanes on the open-space side.
	_add_spot(bench_spots, 2, FURNITURE_OFFSET)
	_add_spot(bench_spots, 5, FURNITURE_OFFSET)
	_add_spot(bench_spots, 11, FURNITURE_OFFSET)
	_add_spot(bus_stop_spots, 4, FURNITURE_OFFSET + 18.0)
	_add_spot(streetlight_spots, 1, 382.0)
	_add_spot(streetlight_spots, 6, 382.0)
	_add_spot(streetlight_spots, 12, 382.0)
	_add_spot(bin_spots, 3, FURNITURE_OFFSET)
	_add_spot(sign_spots, 4, 386.0)
	# Social pockets are outside the pavement, never on asphalt or a walking lane.
	_add_spot(gather_spots, 3, FURNITURE_OFFSET + 34.0)
	_add_spot(gather_spots, 10, FURNITURE_OFFSET + 34.0)

func _add_spot(target: PackedVector2Array, route_index: int, offset: float) -> void:
	var frame := _route_frame(route_index)
	var position: Vector2 = frame.position + frame.normal * offset
	target.append(position)
	prop_rotations[position] = frame.direction.angle()

func _route_frame(index: int) -> Dictionary:
	var size := route.size()
	var previous := route[(index - 1 + size) % size]
	var next := route[(index + 1) % size]
	var direction: Vector2 = (next - previous).normalized()
	return {"position": route[index], "direction": direction, "normal": Vector2(-direction.y, direction.x)}

func get_sit_spots() -> PackedVector2Array:
	var result := PackedVector2Array()
	for bench in bench_spots:
		var rotation: float = prop_rotations.get(bench, 0.0)
		var tangent := Vector2.RIGHT.rotated(rotation)
		var inward := Vector2.DOWN.rotated(rotation)
		result.append(bench - inward * 58.0 - tangent * 28.0)
		result.append(bench - inward * 58.0 + tangent * 28.0)
	return result

func get_gather_spots() -> PackedVector2Array: return gather_spots.duplicate()
func get_prop_count() -> int: return bench_spots.size() + bus_stop_spots.size() + streetlight_spots.size() + bin_spots.size() + sign_spots.size()

func is_point_on_road(point: Vector2) -> bool:
	if route.size() < 2: return false
	for index in route.size():
		if _distance_to_segment(point, route[index], route[(index + 1) % route.size()]) <= ROAD_HALF_WIDTH: return true
	return false

func _distance_to_segment(point: Vector2, a: Vector2, b: Vector2) -> float:
	var segment := b - a
	if segment.length_squared() < 0.001: return point.distance_to(a)
	var amount := clampf((point - a).dot(segment) / segment.length_squared(), 0.0, 1.0)
	return point.distance_to(a + segment * amount)

func _shadow_offset(height: float) -> Vector2:
	if is_instance_valid(light_manager): return light_manager.get_shadow_offset(height)
	return Vector2(10, 15)

func _shadow_color(alpha_scale: float = 1.0) -> Color:
	if is_instance_valid(light_manager): return light_manager.get_shadow_color(alpha_scale)
	return Color(0.08, 0.05, 0.03, 0.28 * alpha_scale)

func _draw() -> void:
	for position in bench_spots: _draw_bench(position, prop_rotations.get(position, 0.0))
	for position in bus_stop_spots: _draw_bus_stop_base(position, prop_rotations.get(position, 0.0))
	for position in streetlight_spots: _draw_streetlight(position)
	for position in bin_spots: _draw_bin(position)
	for position in sign_spots: _draw_bus_sign(position)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_bench(position: Vector2, rotation: float) -> void:
	draw_set_transform(position, rotation, Vector2.ONE)
	var local_shadow := _shadow_offset(8.0).rotated(-rotation)
	draw_rect(Rect2(local_shadow - Vector2(65, 20), Vector2(130, 40)), _shadow_color(0.75), true)
	draw_rect(Rect2(-68, -23, 136, 46), Color("#563423"), true)
	draw_rect(Rect2(-64, -19, 128, 38), Color("#a5673f"), true)
	for y in [-11.0, 0.0, 11.0]: draw_line(Vector2(-59, y), Vector2(59, y), Color("#d0925e"), 5.0, true)
	draw_circle(Vector2(-52, 19), 5.0, Color("#30353a")); draw_circle(Vector2(52, 19), 5.0, Color("#30353a"))

func _draw_bus_stop_base(position: Vector2, rotation: float) -> void:
	draw_set_transform(position, rotation, Vector2.ONE)
	var local_shadow := _shadow_offset(16.0).rotated(-rotation)
	draw_rect(Rect2(local_shadow - Vector2(112, 62), Vector2(224, 124)), _shadow_color(0.70), true)
	# Slab and bench below doodles; glass canopy is a separate overlay above them.
	draw_rect(Rect2(-114, -64, 228, 128), Color("#705f50"), true)
	draw_rect(Rect2(-108, -58, 216, 116), Color("#bcae96"), true)
	draw_line(Vector2(-104, -45), Vector2(104, -45), Color("#d7c9b0"), 5.0, true)
	draw_rect(Rect2(-68, 12, 136, 27), Color("#513523"), true)
	draw_rect(Rect2(-63, 8, 126, 24), Color("#a96840"), true)
	for x in [-48.0, 0.0, 48.0]: draw_line(Vector2(x, 11), Vector2(x, 29), Color("#d29865"), 3.0, true)

func _draw_streetlight(position: Vector2) -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var end := position + _shadow_offset(27.0)
	var direction := position.direction_to(end); var perpendicular := Vector2(-direction.y, direction.x)
	# One polygon and alpha pass prevents pole/lamp shadow stacking.
	var shadow_shape := PackedVector2Array([position - perpendicular * 5.0, position + perpendicular * 5.0, end + perpendicular * 11.0 + direction * 7.0, end - perpendicular * 11.0 + direction * 7.0])
	draw_colored_polygon(shadow_shape, _shadow_color(0.82))
	draw_circle(position, 11.0, Color("#30353b")); draw_circle(position, 7.0, Color("#7f8990")); draw_circle(position + Vector2(0, -2), 3.0, Color("#ffe1a0"))

func _draw_bin(position: Vector2) -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_circle(position + _shadow_offset(7.0), 17.0, _shadow_color(0.65))
	draw_circle(position, 17.0, Color("#315a51")); draw_circle(position, 13.0, Color("#4c8072"))
	draw_line(position + Vector2(-10, -3), position + Vector2(10, -3), Color("#a8c2a9"), 3.0, true)

func _draw_bus_sign(position: Vector2) -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var end := position + _shadow_offset(19.0)
	var direction := position.direction_to(end); var perpendicular := Vector2(-direction.y, direction.x)
	var shadow_shape := PackedVector2Array([position - perpendicular * 4.0, position + perpendicular * 4.0, end + perpendicular * 30.0 + direction * 5.0, end - perpendicular * 30.0 + direction * 5.0])
	draw_colored_polygon(shadow_shape, _shadow_color(0.70))
	draw_circle(position, 8.0, Color("#4b5055"))
	draw_rect(Rect2(position + Vector2(-31, -37), Vector2(62, 29)), Color("#276f7b"), true)
	draw_rect(Rect2(position + Vector2(-31, -37), Vector2(62, 29)), Color("#e5f2e9"), false, 3.0)
	# Recognizable bus silhouette replaces the old abstract white boxes.
	draw_rect(Rect2(position + Vector2(-20, -30), Vector2(40, 13)), Color("#eaf2df"), true)
	draw_circle(position + Vector2(-13, -15), 3.0, Color("#2d5258")); draw_circle(position + Vector2(13, -15), 3.0, Color("#2d5258"))

func _create_collisions() -> void:
	var holder := Node2D.new(); holder.name = "FurnitureCollisions"; add_child(holder)
	for position in bench_spots: _add_box_collision(holder, position, prop_rotations.get(position, 0.0), Vector2(138, 48), "Bench")
	for position in bus_stop_spots:
		var rotation: float = prop_rotations.get(position, 0.0)
		var right := Vector2.RIGHT.rotated(rotation); var down := Vector2.DOWN.rotated(rotation)
		_add_box_collision(holder, position + down * 55.0, rotation, Vector2(224, 14), "ShelterBack")
		_add_box_collision(holder, position - right * 105.0, rotation, Vector2(14, 116), "ShelterSide")
		_add_box_collision(holder, position + right * 105.0, rotation, Vector2(14, 116), "ShelterSide")
		_add_box_collision(holder, position + down * 22.0, rotation, Vector2(136, 27), "ShelterBench")
	for position in streetlight_spots: _add_circle_collision(holder, position, 13.0, "Streetlight")
	for position in bin_spots: _add_circle_collision(holder, position, 19.0, "Bin")
	for position in sign_spots: _add_circle_collision(holder, position, 10.0, "BusSign")

func _add_box_collision(parent: Node, position: Vector2, rotation: float, size: Vector2, label: String) -> void:
	var body := StaticBody2D.new(); body.name = label; body.position = position; body.rotation = rotation
	var shape_node := CollisionShape2D.new(); var shape := RectangleShape2D.new(); shape.size = size; shape_node.shape = shape
	body.add_child(shape_node); parent.add_child(body)

func _add_circle_collision(parent: Node, position: Vector2, radius: float, label: String) -> void:
	var body := StaticBody2D.new(); body.name = label; body.position = position
	var shape_node := CollisionShape2D.new(); var shape := CircleShape2D.new(); shape.radius = radius; shape_node.shape = shape
	body.add_child(shape_node); parent.add_child(body)

func _create_shelter_roofs() -> void:
	for position in bus_stop_spots:
		var roof = ShelterRoofScript.new(); roof.name = "GlassShelterRoof"; roof.position = position; roof.rotation = prop_rotations.get(position, 0.0); roof.light_manager = light_manager
		add_child(roof)
