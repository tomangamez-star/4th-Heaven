extends SceneTree

func check(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		quit(1)
		assert(ok,message)

func _init() -> void:
	call_deferred("run")

func run() -> void:
	var world := Node2D.new(); root.add_child(world)
	var roads = load("res://scripts/raster_roads.gd").new(); world.add_child(roads)
	for point in [Vector2(1500,440),Vector2(1750,440),Vector2(2350,440),Vector2(2180,-570),Vector2(2250,-570)]:
		check(roads.is_on_road(point),"Disconnected asphalt at "+str(point))
	check(not roads.is_on_road(Vector2(0,430)),"Road covers central park")
	var player := CharacterBody2D.new(); world.add_child(player)
	var collider := CollisionShape2D.new(); var circle := CircleShape2D.new(); circle.radius=33.0
	collider.shape=circle; player.add_child(collider)
	var camera := Camera2D.new(); camera.name="PlayerCamera"; player.add_child(camera)
	var controls = load("res://scripts/touch_controls.gd").new(); world.add_child(controls)
	var car = load("res://scripts/driveable_car.gd").new()
	car.player=player; car.controls=controls; car.road_surface=roads
	car.position=Vector2(-700,-178); car.rotation=PI/2.0; world.add_child(car)
	car.set_physics_process(false)
	controls.movement_vector=Vector2(0,-1)
	car._enter_vehicle()
	await physics_frame
	check(collider.disabled,"Unnamed player collider remained active inside car")
	check(controls.movement_vector==Vector2.ZERO,"Entry inherited throttle")
	check(car.get_collision_exceptions().has(player),"Missing driver collision exception")
	var start_angle: float=car.rotation
	for frame in 30: car._drive(0.0,1.0,1.0/60.0)
	check(is_equal_approx(car.rotation,start_angle),"Stopped car pivots in place")
	var max_step := 0.0
	for frame in 180:
		await physics_frame
		var before: Vector2=car.position
		car._drive(1.0,0.0,1.0/60.0)
		car._update_camera(1.0/60.0)
		max_step=maxf(max_step,before.distance_to(car.position))
		check(before.distance_to(car.position)<6.0,"Driving teleported more than one physics step")
		check(car.position.distance_to(car.vehicle_camera.global_position)<=48.1,"Car escaped camera")
	check(car.speed>200.0 and car.speed<=car.FORWARD_SPEED,"Acceleration/speed bound failed")
	# Brake must reach rest before reverse engages.
	car._drive(-1.0,0.0,1.0/60.0)
	check(car.speed>0.0 and car.braking,"Reverse immediately flipped driving direction")
	for frame in 160:
		await physics_frame
		car._drive(-1.0,0.0,1.0/60.0)
	check(car.speed<0.0 and absf(car.speed)<=car.REVERSE_SPEED,"Reverse failed after braking")
	car.speed=0.0; car.travel_velocity=Vector2.ZERO
	car._exit_vehicle()
	await physics_frame
	check(not car.occupied and not collider.disabled,"Exit did not restore player")
	# An isolated swept-body collision must stop without crossing a wall.
	car.global_position=Vector2(-2300,-1000); car.rotation=PI/2.0
	car._enter_vehicle()
	var wall:=StaticBody2D.new(); wall.position=Vector2(-2050,-1000)
	var wall_shape:=CollisionShape2D.new(); var rectangle:=RectangleShape2D.new(); rectangle.size=Vector2(20,500)
	wall_shape.shape=rectangle; wall.add_child(wall_shape); world.add_child(wall)
	await physics_frame
	for frame in 240:
		await physics_frame
		var before: Vector2=car.position
		car._drive(1.0,0.0,1.0/60.0)
		check(before.distance_to(car.position)<6.0,"Wall collision teleported the car")
	check(car.position.x < -2160.0,"Car crossed the wall")
	check(car.speed<=110.0,"Off-road speed cap failed")
	print("v0.2.4 driving regressions passed; max frame displacement: ",max_step)
	quit(0)
