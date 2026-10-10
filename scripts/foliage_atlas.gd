extends RefCounted

const SHEET = preload("res://assets/environment/foliage_atlas.png")
static var parts: Array[AtlasTexture] = []

static func get_part(index: int) -> AtlasTexture:
	if parts.is_empty():
		var source := SHEET.get_image()
		var cell := Vector2i(source.get_width() / 2, source.get_height() / 2)
		for i in 4:
			var origin := Vector2i(i % 2, i / 2) * cell
			var used := source.get_region(Rect2i(origin, cell)).get_used_rect()
			var part := AtlasTexture.new()
			part.atlas = SHEET
			part.region = Rect2(origin + used.position, used.size)
			part.filter_clip = true
			parts.append(part)
	return parts[clampi(index, 0, 3)]
