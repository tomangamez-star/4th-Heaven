extends Node2D

const BUILDINGS = preload("res://assets/environment/market_buildings.png")
const PAVEMENT = preload("res://assets/roads/pavement.png")
const VisitorScript = preload("res://scripts/district_visitor.gd")
const CENTERS := [Vector2(1900, -60), Vector2(2800, -60)]
const DOORS := [Vector2(1900, 160), Vector2(2800, 160)]
const TITLES := ["Corner Cafe", "Neighbourhood Store"]
var light_manager
var doorway_lights: Array[PointLight2D] = []
var floor_areas: Array[Rect2] = []
var building_shadows: Array[Sprite2D] = []

func _ready() -> void:
	name = "MarketDistrict"
	add_to_group("world_lit_visual")
	z_index = -2
	light_manager = get_tree().get_first_node_in_group("world_light")
	var source := BUILDINGS.get_image()
	var half := Vector2i(source.get_width() / 2, source.get_height())
	for index in 2:
		var origin := Vector2i(index * half.x, 0)
		var used := source.get_region(Rect2i(origin, half)).get_used_rect()
		var texture := AtlasTexture.new()
		texture.atlas = BUILDINGS
		texture.region = Rect2(origin + used.position, used.size)
		texture.filter_clip = true
		var art := Sprite2D.new()
		art.name = TITLES[index].replace(" ", "")
		art.texture = texture
		art.position = CENTERS[index]
		art.scale = Vector2(410.0 / texture.get_width(), 400.0 / texture.get_height())
		art.z_as_relative = false
		art.z_index = 12
		var shadow := Sprite2D.new()
		shadow.name = "ShopSilhouetteShadow%d" % index
		shadow.texture = texture; shadow.scale = art.scale
		shadow.z_as_relative = false; shadow.z_index = 3
		add_child(shadow); building_shadows.append(shadow)
		add_child(art)
		var body := StaticBody2D.new()
		body.name = "ShopWall%d" % index
		body.position = CENTERS[index] + Vector2(0, -20)
		var collider := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(410, 330)
		collider.shape = shape
		body.add_child(collider)
		add_child(body)
		floor_areas.append(Rect2(CENTERS[index] + Vector2(-220, -205), Vector2(440, 515)))
		_add_storefront_label(index)
		_add_door_light(DOORS[index])
		var visitor = VisitorScript.new()
		visitor.name = "MarketVisitor%d" % index
		visitor.is_npc = true
		visitor.appearance_id = index + 7
		visitor.shop_door = DOORS[index]
		visitor.add_to_group("doodles")
		visitor.add_to_group("npc")
		add_child(visitor)
		visitor.configure_route(PackedVector2Array([DOORS[index], DOORS[index] + Vector2(110, 70), DOORS[index] + Vector2(-110, 70)]), 1, 0.43 + index * 0.10)
		visitor.configure_behavior_spots(PackedVector2Array(), PackedVector2Array(), index + 10)
		visitor.behavior_cooldown = 1.0
	_add_market_gateway()
	if is_instance_valid(light_manager):
		light_manager.time_state_changed.connect(_on_time_changed)
		_on_time_changed(light_manager.current_state)
	_update_building_shadows()

func _draw() -> void:
	for area in floor_areas:
		# Existing raster paving extends only up to the pavement, never onto asphalt.
		draw_texture_rect(PAVEMENT, area, true)
	for index in CENTERS.size():
		var center: Vector2 = CENTERS[index]
		var door: Vector2 = DOORS[index]
		draw_rect(Rect2(door + Vector2(-92, 32), Vector2(184, 62)), Color("#46382d"), true)
		draw_rect(Rect2(door + Vector2(-86, 38), Vector2(172, 50)), Color("#ead1a2"), true)
		draw_colored_polygon(PackedVector2Array([door + Vector2(-18, 96), door + Vector2(18, 96), door + Vector2(0, 122)]), Color("#d36b4e" if index == 0 else "#4a9b82"))

func _add_storefront_label(index: int) -> void:
	var label := Label.new()
	label.name = "ShopSign%d" % index
	label.text = "CORNER CAFE" if index == 0 else "NEIGHBOURHOOD SHOP"
	label.position = DOORS[index] + Vector2(-112, 43)
	label.size = Vector2(224, 34)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", Color("#33261e"))
	label.z_as_relative = false; label.z_index = 14
	add_child(label)

func _add_market_gateway() -> void:
	var sign := Label.new(); sign.name = "MarketStreetGateway"
	sign.text = "MARKET STREET  →\nCAFE  •  SHOP"
	sign.position = Vector2(1480, 70); sign.size = Vector2(330, 92)
	sign.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; sign.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sign.add_theme_font_size_override("font_size", 23)
	sign.add_theme_color_override("font_color", Color("#fff0c8")); sign.add_theme_color_override("font_shadow_color", Color(0.08, 0.04, 0.02, 0.9))
	sign.add_theme_constant_override("shadow_offset_x", 3); sign.add_theme_constant_override("shadow_offset_y", 3)
	sign.z_as_relative = false; sign.z_index = 16; add_child(sign)

func _update_building_shadows() -> void:
	var offset: Vector2 = light_manager.get_shadow_offset(22.0) if is_instance_valid(light_manager) else Vector2(12, 18)
	var color: Color = light_manager.get_shadow_color(0.82) if is_instance_valid(light_manager) else Color(0.03, 0.02, 0.015, 0.25)
	for index in building_shadows.size():
		building_shadows[index].position = CENTERS[index] + offset
		building_shadows[index].modulate = color

func _add_door_light(location: Vector2) -> void:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 0.7))
	gradient.set_color(1, Color(1, 1, 1, 0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 256
	texture.height = 256
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1, 0.5)
	var lamp := PointLight2D.new()
	lamp.texture = texture
	lamp.position = location
	lamp.color = Color("#ffdaa0")
	lamp.energy = 1.2
	add_child(lamp)
	doorway_lights.append(lamp)

func _on_time_changed(state: String) -> void:
	for lamp in doorway_lights: lamp.enabled = state == "night"
	_update_building_shadows()
	queue_redraw()
