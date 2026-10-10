extends CanvasLayer

var player
var controls
var furniture
var market
var panel: HBoxContainer
var greet_button: Button
var sit_button: Button
var shop_button: Button
var message: Label
var message_time := 0.0
var refresh_time := 0.0
var nearest_npc
var nearest_seat := Vector2.INF
var nearest_shop := -1
var social_time := 2.0

func _ready() -> void:
	layer = 21
	panel = HBoxContainer.new()
	panel.add_theme_constant_override("separation", 8)
	add_child(panel)
	greet_button = _button("GREET", _greet)
	sit_button = _button("SIT", _sit)
	shop_button = _button("SHOP", _shop)
	_button("WAVE", func(): player.personality.emote("wave"))
	_button("STRETCH", func(): player.personality.emote("stretch"))
	message = Label.new()
	message.add_theme_font_size_override("font_size", 19)
	message.add_theme_color_override("font_shadow_color", Color.BLACK)
	message.add_theme_constant_override("shadow_offset_x", 2)
	message.add_theme_constant_override("shadow_offset_y", 2)
	message.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(message)
	get_viewport().size_changed.connect(_reflow)
	_reflow()
	_notify("New: head glances + emotes. Shops are beside the east junction.", 7.0)

func _button(title: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size = Vector2(94, 48)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(action)
	panel.add_child(button)
	return button

func _reflow() -> void:
	var view := get_viewport().get_visible_rect().size
	panel.position = Vector2(maxf(260.0, view.x - 530.0), 90)
	message.position = Vector2(25, 155)

func _process(delta: float) -> void:
	social_time -= delta
	if social_time <= 0.0:
		social_time = 3.0
		_pair_nearby_friends()
	var enabled: bool = is_instance_valid(player) and player.visible and not controls.driving_mode and not player.ragdoll_active
	panel.visible = enabled
	message_time = maxf(0.0, message_time - delta)
	message.visible = enabled and message_time > 0.0
	if not enabled: return
	refresh_time -= delta
	if refresh_time > 0.0: return
	refresh_time = 0.15
	nearest_npc = null
	var best := 155.0
	for npc in get_tree().get_nodes_in_group("npc"):
		if not npc.visible or npc.ragdoll_active or npc.visual.modulate.a < 0.5: continue
		var distance: float = player.global_position.distance_to(npc.global_position)
		if distance < best and _clear_path(npc.global_position, npc):
			best = distance
			nearest_npc = npc
	greet_button.disabled = not is_instance_valid(nearest_npc)
	nearest_seat = Vector2.INF
	for seat in furniture.get_sit_spots():
		if player.global_position.distance_to(seat) < 65.0 and _clear_path(seat):
			var occupied := false
			for npc in get_tree().get_nodes_in_group("npc"):
				if npc.global_position.distance_to(seat) < 65.0: occupied = true
			if not occupied: nearest_seat = seat
	sit_button.text = "STAND" if player.is_sitting else "SIT"
	sit_button.disabled = not player.is_sitting and nearest_seat == Vector2.INF
	nearest_shop = -1
	for index in market.DOORS.size():
		if player.global_position.distance_to(market.DOORS[index]) < 135.0 and _clear_path(market.DOORS[index]): nearest_shop = index
	shop_button.disabled = nearest_shop < 0

func _clear_path(target: Vector2, other = null) -> bool:
	var ray := PhysicsRayQueryParameters2D.create(player.global_position, target)
	ray.exclude = [player.get_rid()]
	if is_instance_valid(other): ray.exclude.append(other.get_rid())
	return player.get_world_2d().direct_space_state.intersect_ray(ray).is_empty()

func _greet() -> void:
	if not is_instance_valid(nearest_npc) or player.global_position.distance_to(nearest_npc.global_position) > 155.0: return
	player.personality.emote("wave")
	player.personality.attention_target = nearest_npc
	player.personality.attention_time = 3.5
	_notify(nearest_npc.personality.greet(player))
	nearest_npc.behavior_state = "talk"
	nearest_npc.behavior_timer = 3.0
	nearest_npc.behavior_look_direction = nearest_npc.global_position.direction_to(player.global_position)

func _sit() -> void:
	if player.is_sitting:
		player.is_sitting = false
		player.behavior_state = "walk"
	elif nearest_seat != Vector2.INF:
		# Only complete the short seating step if the whole body can travel there.
		var motion: Vector2 = nearest_seat - player.global_position
		if player.test_move(player.global_transform, motion):
			_notify("That seat is blocked. Try the other side.")
			return
		player.move_and_collide(motion)
		player.is_sitting = true
		for bench in furniture.bench_spots:
			if bench.distance_to(nearest_seat) < 85.0:
				player.facing = Vector2.UP.rotated(float(furniture.prop_rotations.get(bench, 0.0)))
				player.display_facing = player.facing
				break
		player.velocity = Vector2.ZERO
		_notify("Resting. Move the joystick or tap STAND to get up.")

func _shop() -> void:
	if nearest_shop < 0: return
	player.personality.emote("wave")
	_notify("%s: Welcome! %s" % [market.TITLES[nearest_shop], "Take a breather with us." if nearest_shop == 0 else "Just browsing? You're welcome here."])

func _notify(text: String, duration: float = 3.5) -> void:
	message.text = text
	message_time = duration

func _pair_nearby_friends() -> void:
	var npcs := get_tree().get_nodes_in_group("npc")
	for i in npcs.size():
		var a = npcs[i]
		if not a.visible or a.visual.modulate.a < 0.5 or a.ragdoll_active or a.behavior_state != "walk" or a.behavior_cooldown > 0.0: continue
		for j in range(i + 1, npcs.size()):
			var b = npcs[j]
			if not b.visible or b.visual.modulate.a < 0.5 or b.ragdoll_active or b.behavior_state != "walk" or b.behavior_cooldown > 0.0: continue
			if a.global_position.distance_to(b.global_position) > 135.0: continue
			var ray := PhysicsRayQueryParameters2D.create(a.global_position, b.global_position)
			ray.exclude = [a.get_rid(), b.get_rid()]
			if not a.get_world_2d().direct_space_state.intersect_ray(ray).is_empty(): continue
			for pair in [[a, b], [b, a]]:
				var actor = pair[0]
				var other = pair[1]
				actor.behavior_state = "talk"
				actor.behavior_timer = 3.5
				actor.behavior_cooldown = 16.0
				actor.behavior_look_direction = actor.global_position.direction_to(other.global_position)
				actor.personality.greet(other)
			return
