extends "res://scripts/doodle_player.gd"

var shop_door := Vector2.ZERO
var inside_time := 0.0
var visit_cooldown := 9.0

func _update_npc(delta: float) -> void:
	visit_cooldown = maxf(0.0, visit_cooldown - delta)
	if inside_time > 0.0:
		inside_time -= delta
		velocity = Vector2.ZERO
		visual.modulate.a = 0.0
		if inside_time <= 0.0:
			# Wait inside if somebody is standing in the doorway. No exit teleport.
			var query := PhysicsShapeQueryParameters2D.new()
			query.shape = $CollisionShape2D.shape
			query.transform = global_transform
			query.exclude = [get_rid()]
			if not get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty():
				inside_time = 0.5
				return
			visual.modulate.a = 1.0
			$CollisionShape2D.set_deferred("disabled", false)
			personality.emote("wave")
			visit_cooldown = 22.0
			resume_nearest_route()
			# Leave the doorway rather than immediately target it again.
			route_index = 1
		return
	if visit_cooldown <= 0.0 and global_position.distance_to(shop_door) < 22.0:
		inside_time = 4.5
		velocity = Vector2.ZERO
		$CollisionShape2D.set_deferred("disabled", true)
		return
	super._update_npc(delta)
