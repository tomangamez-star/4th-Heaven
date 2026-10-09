extends Node2D

const SOIL = preload("res://assets/environment/soil.png")
const SOIL_WEB = preload("res://assets/environment/soil_web.png")

func _ready() -> void:
	z_index = -100
	var web := OS.has_feature("web")
	var texture: Texture2D = SOIL_WEB if web else SOIL
	var scale_factor := 2.0 if web else 1.0
	for x in range(-3072, 3073, 1024):
		for y in range(-2048, 2049, 1024):
			var tile := Sprite2D.new()
			tile.texture = texture
			tile.centered = false
			tile.position = Vector2(x, y)
			tile.scale = Vector2.ONE * scale_factor
			add_child(tile)
