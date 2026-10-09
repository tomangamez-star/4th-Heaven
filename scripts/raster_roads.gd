extends Node2D

# No runtime road outlines or overlapping shape masks. The PNG chunks already
# contain the connected asphalt, pavement, curbs, crosswalks and lane paint.
var tiles: Array = []
var surfaces: Array = []
var sprites: Dictionary = {}
var refresh_time := 0.0

func _ready() -> void:
	z_index = -3
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://assets/roads/map.json"))
	tiles = data.tiles
	for polygon in data.roads:
		var holes: Array = []
		for ring in polygon.holes: holes.append(_points(ring))
		surfaces.append({"outer": _points(polygon.outer), "holes": holes})
	_refresh_tiles()

func _points(source: Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in source: result.append(Vector2(point[0], point[1]))
	return result

func is_on_road(point: Vector2) -> bool:
	for surface in surfaces:
		if not Geometry2D.is_point_in_polygon(point, surface.outer): continue
		var in_hole := false
		for hole in surface.holes:
			if Geometry2D.is_point_in_polygon(point, hole): in_hole = true
		if not in_hole: return true
	return false

func _process(delta: float) -> void:
	refresh_time -= delta
	if refresh_time <= 0.0:
		refresh_time = 0.20
		_refresh_tiles()

func _refresh_tiles() -> void:
	var camera := get_viewport().get_camera_2d()
	var center := camera.get_screen_center_position() if is_instance_valid(camera) else Vector2.ZERO
	var zoom := camera.zoom if is_instance_valid(camera) else Vector2.ONE
	var half := get_viewport_rect().size / zoom * 0.5 + Vector2(420,420)
	var view := Rect2(center-half,half*2.0)
	for tile in tiles:
		var key: String = tile.file
		var area := Rect2(float(tile.x),float(tile.y),1024,1024)
		if view.intersects(area):
			if not sprites.has(key):
				var sprite := Sprite2D.new()
				var web := OS.has_feature("web")
				sprite.texture = load("res://assets/roads/" + ("web/" if web else "") + key)
				sprite.scale = Vector2(2, 2) if web else Vector2.ONE
				sprite.centered = false
				sprite.position = area.position
				add_child(sprite)
				sprites[key] = sprite
		elif sprites.has(key):
			sprites[key].queue_free()
			sprites.erase(key)
