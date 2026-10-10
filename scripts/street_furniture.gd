extends Node2D

const ShelterRoofScript = preload("res://scripts/shelter_roof_overlay.gd")
const STREETLIGHT_TEXTURE = preload("res://assets/environment/streetlight_top.png")
const ROAD_HALF_WIDTH := 190.0
const FURNITURE_OFFSET := 430.0

var light_manager
var route := PackedVector2Array()
var bench_spots := PackedVector2Array()
var bus_stop_spots := PackedVector2Array()
var gather_spots := PackedVector2Array()
var streetlight_spots := PackedVector2Array()
var roadlight_spots := PackedVector2Array()
var bin_spots := PackedVector2Array()
var sign_spots := PackedVector2Array()
var prop_rotations: Dictionary = {}
var light_directions: Dictionary = {}
var road_surfaces: Array = []

func configure(points: PackedVector2Array) -> void:
	route = points.duplicate()
	_rebuild_layout()

func _ready() -> void:
	z_index = 4
	add_to_group("street_furniture")
	add_to_group("world_lit_visual")
	var lights := get_tree().get_nodes_in_group("world_light")
	if not lights.is_empty(): light_manager = lights[0]
	_create_collisions()
	_create_shelter_roofs()
	_create_street_lights()
	if is_instance_valid(light_manager):
		light_manager.time_state_changed.connect(_on_time_state_changed)
		_on_time_state_changed(light_manager.current_state)
	queue_redraw()

func _rebuild_layout() -> void:
	bench_spots.clear(); bus_stop_spots.clear(); gather_spots.clear()
	streetlight_spots.clear(); roadlight_spots.clear(); bin_spots.clear(); sign_spots.clear(); prop_rotations.clear()
	light_directions.clear()
	if route.size() < 8: return
	# Sparse, deliberate furniture beyond both pedestrian lanes on the open-space side.
	_add_spot(bench_spots, 2, FURNITURE_OFFSET)
	_add_spot(bench_spots, 5, FURNITURE_OFFSET)
	_add_spot(bench_spots, 11, FURNITURE_OFFSET)
	_add_spot(bus_stop_spots, 4, FURNITURE_OFFSET + 18.0)
	_populate_street_lights()
	_add_spot(bin_spots, 3, FURNITURE_OFFSET)
	_add_spot(sign_spots, 4, 386.0)
	# Social pockets are outside the pavement, never on asphalt or a walking lane.
	# Keep social pockets clear of the new station footprint and prop collisions.
	_add_spot(gather_spots, 1, FURNITURE_OFFSET + 34.0)
	_add_spot(gather_spots, 6, FURNITURE_OFFSET + 34.0)

func _add_spot(target: PackedVector2Array, route_index: int, offset: float) -> void:
	var frame := _route_frame(route_index)
	var position: Vector2 = frame.position + frame.normal * offset
	target.append(position)
	prop_rotations[position] = frame.direction.angle()

func _populate_street_lights() -> void:
	road_surfaces.clear()
	var map_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/roads/map.json"))
	for polygon in map_data.roads:
		var outer := PackedVector2Array()
		for vertex in polygon.outer: outer.append(Vector2(vertex[0], vertex[1]))
		var holes: Array = []
		for ring in polygon.holes:
			var hole := PackedVector2Array()
			for vertex in ring: hole.append(Vector2(vertex[0], vertex[1]))
			holes.append(hole)
		road_surfaces.append({"outer": outer, "holes": holes})
	# One deliberate fixture per oval route node prevents doubled poles at corners.
	for index in route.size():
		var frame := _route_frame(index)
		var side := 1.0 if index % 2 == 0 else -1.0
		_register_lamp(frame.position + frame.normal * 382.0 * side, -frame.normal * side, frame.direction.angle(), side > 0.0)
	# Staggered extension lights keep the shop-facing pavement clear and illuminate
	# both lanes without the clustered automatic relocation from the prior patch.
	for data in [
		[Vector2(1580, 1000), Vector2.UP, 0.0, true], [Vector2(1840, 1000), Vector2.UP, 0.0, false],
		[Vector2(2120, 1000), Vector2.UP, 0.0, true], [Vector2(2600, 1000), Vector2.UP, 0.0, false],
		[Vector2(2720, 1000), Vector2.UP, 0.0, true], [Vector2(2920, 1000), Vector2.UP, 0.0, false],
		[Vector2(1968, -1320), Vector2.RIGHT, PI * 0.5, true], [Vector2(2732, -1040), Vector2.LEFT, PI * 0.5, false],
		[Vector2(2732, -620), Vector2.LEFT, PI * 0.5, true], [Vector2(2732, -180), Vector2.LEFT, PI * 0.5, false],
		[Vector2(1968, 1080), Vector2.RIGHT, PI * 0.5, true], [Vector2(2732, 1380), Vector2.LEFT, PI * 0.5, false]
	]:
		_register_lamp(data[0], data[1], data[2], data[3])

func _register_lamp(position: Vector2, inward: Vector2, tangent_angle: float, primary: bool) -> void:
	if primary: streetlight_spots.append(position)
	else: roadlight_spots.append(position)
	prop_rotations[position] = tangent_angle
	light_directions[position] = inward.normalized()

func _fixture_on_road(point: Vector2, segments: Array) -> bool:
	for surface in road_surfaces:
		if Geometry2D.is_point_in_polygon(point, surface.outer):
			var inside_hole := false
			for hole in surface.holes:
				if Geometry2D.is_point_in_polygon(point, hole): inside_hole = true
			if not inside_hole: return true
	for segment in segments:
		if _distance_to_segment(point, segment[0], segment[1]) < 215.0: return true
	if Rect2(1550, -1055, 650, 590).has_point(point): return true
	for center in [Vector2(1900, -60), Vector2(2800, -60)]:
		if Rect2(center - Vector2(205, 225), Vector2(410, 445)).has_point(point): return true
	return absf(point.x) > 2980.0 or absf(point.y) > 1980.0

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
		result.append(bench - inward * 72.0 - tangent * 28.0)
		result.append(bench - inward * 72.0 + tangent * 28.0)
	return result

func get_gather_spots() -> PackedVector2Array: return gather_spots.duplicate()
func get_prop_count() -> int: return bench_spots.size() + bus_stop_spots.size() + streetlight_spots.size() + roadlight_spots.size() + bin_spots.size() + sign_spots.size()

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
	for position in roadlight_spots: _add_circle_collision(holder, position, 13.0, "RoadLight")
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

func _lamp_box() -> StyleBoxFlat:
	var box := StyleBoxFlat.new(); box.bg_color = Color("#28333a"); box.border_color = Color("#7c898e")
	box.set_border_width_all(2); box.set_corner_radius_all(7)
	return box

func _create_street_lights() -> void:
	var texture := _radial_light_texture()
	var head_texture := _lamp_head_texture()
	var all_lights := streetlight_spots + roadlight_spots
	var overlay := Node2D.new(); overlay.name = "StreetlightArtOverlay"
	overlay.z_as_relative = false; overlay.z_index = 14; add_child(overlay)
	for index in all_lights.size():
		var fixture_position: Vector2 = all_lights[index]
		var direction: Vector2 = light_directions.get(fixture_position, fixture_position.direction_to(_nearest_route_point(fixture_position)))
		var art := Sprite2D.new(); art.name = "StreetlightArt%d" % index
		art.texture = STREETLIGHT_TEXTURE; art.centered = false
		art.offset = Vector2(-22, -35); art.position = fixture_position; art.rotation = direction.angle()
		overlay.add_child(art)
		var head_position := fixture_position + direction * 132.0
		var head_lamp := PointLight2D.new(); head_lamp.name = "LampHeadGlow%d" % index
		head_lamp.position = head_position; head_lamp.texture = head_texture
		head_lamp.texture_scale = 0.82; head_lamp.energy = 1.85; head_lamp.color = Color("#ffe0a0")
		head_lamp.add_to_group("night_fixture_light"); add_child(head_lamp)
		var glow_position := fixture_position + direction * 360.0
		var lamp := PointLight2D.new(); lamp.name = "StreetGlow%d" % index
		lamp.position = glow_position
		lamp.rotation = prop_rotations.get(fixture_position, 0.0)
		lamp.texture = texture; lamp.texture_scale = 2.15
		lamp.energy = 1.25; lamp.color = Color("#ffd78c")
		lamp.add_to_group("night_street_light")
		add_child(lamp)

func _nearest_route_point(point: Vector2) -> Vector2:
	var nearest := Vector2.ZERO
	var nearest_distance := INF
	for index in route.size():
		var a := route[index]
		var b := route[(index + 1) % route.size()]
		var segment := b - a
		var amount := clampf((point - a).dot(segment) / maxf(segment.length_squared(), 0.001), 0.0, 1.0)
		var route_point := a + segment * amount
		var distance := point.distance_squared_to(route_point)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = route_point
	return nearest

func _radial_light_texture() -> GradientTexture2D:
	var gradient := Gradient.new(); gradient.set_color(0, Color(1, 1, 1, 0.95)); gradient.set_color(1, Color(1, 1, 1, 0.0))
	var texture := GradientTexture2D.new(); texture.gradient = gradient; texture.width = 420; texture.height = 320
	texture.fill = GradientTexture2D.FILL_RADIAL; texture.fill_from = Vector2(0.5, 0.5); texture.fill_to = Vector2(1.0, 0.5)
	return texture

func _lamp_head_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 1.0)); gradient.add_point(0.22, Color(1.0, 0.86, 0.48, 0.92)); gradient.set_color(1, Color(1, 1, 1, 0.0))
	var texture := GradientTexture2D.new(); texture.gradient = gradient; texture.width = 96; texture.height = 96
	texture.fill = GradientTexture2D.FILL_RADIAL; texture.fill_from = Vector2(0.5, 0.5); texture.fill_to = Vector2(1.0, 0.5)
	return texture

func _on_time_state_changed(state_name: String) -> void:
	var enabled := state_name == "night"
	for lamp in get_tree().get_nodes_in_group("night_street_light"):
		if lamp.is_ancestor_of(self) or lamp.get_parent() == self: lamp.enabled = enabled
	for lamp in get_tree().get_nodes_in_group("night_fixture_light"):
		if lamp.get_parent() == self: lamp.enabled = enabled
	queue_redraw()
