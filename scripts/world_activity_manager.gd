extends Node

var player: Node2D
var refresh_time := 0.0
var active_count := 0

func _process(delta: float) -> void:
	refresh_time -= delta
	if refresh_time > 0.0 or not is_instance_valid(player):
		return
	refresh_time = 0.34 if OS.has_feature("web") else 0.22
	var viewport_size := player.get_viewport_rect().size
	var camera := player.get_viewport().get_camera_2d()
	var zoom := camera.zoom if is_instance_valid(camera) else Vector2.ONE
	var half_view := viewport_size * 0.5 / zoom
	var wake_radius := half_view.length() + (90.0 if OS.has_feature("web") else 180.0)
	active_count = 0
	for actor in get_tree().get_nodes_in_group("world_activity"):
		if not is_instance_valid(actor) or not actor.has_method("set_world_activity"):
			continue
		var active := player.global_position.distance_to(actor.global_position) <= wake_radius
		actor.set_world_activity(active)
		if active:
			active_count += 1
