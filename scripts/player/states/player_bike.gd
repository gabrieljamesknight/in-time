extends State

const BIKE_SCENE = preload("res://scenes/interactables/interactive_bike.tscn")

# -- BIKE SETTINGS --
var bike_speed = 12.0
var acceleration = 4.0
var friction = 2.0 

# -- WIPEOUT SETTINGS --
var crash_speed_threshold = 8.0
var impact_angle_threshold = -0.5 

# -- SPAWN SETTINGS --
var spawn_distance = 1.5 
# Distance from the floor to the center of the bike. 
# Since the bike mesh is 1.0m tall, the center is 0.5m.
var bike_half_height = 0.5 

var dismount_cooldown = 0.2

func enter() -> void:
	print("State: Bike Mode Activated")
	dismount_cooldown = 0.2

func physics_update(delta: float) -> void:
	# 1. Cooldown
	if dismount_cooldown > 0:
		dismount_cooldown -= delta
		
	# 2. Manual Dismount
	if dismount_cooldown <= 0 and Input.is_action_just_pressed("interact"):
		spawn_bike_prop(false)
		get_parent().change_state("idle")
		return
		
	# Gravity
	if not player.is_on_floor():
		player.velocity.y -= player.gravity * delta
	
	# Movement
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	var current_horizontal_speed = Vector2(player.velocity.x, player.velocity.z).length()
	
	if direction:
		player.velocity.x = move_toward(player.velocity.x, direction.x * bike_speed, acceleration * delta)
		player.velocity.z = move_toward(player.velocity.z, direction.z * bike_speed, acceleration * delta)
	else:
		player.velocity.x = move_toward(player.velocity.x, 0, friction * delta)
		player.velocity.z = move_toward(player.velocity.z, 0, friction * delta)
	
	var velocity_before_collision = player.velocity
	
	player.move_and_slide()
	
	# 3. Crash Detection
	if current_horizontal_speed > crash_speed_threshold and player.get_slide_collision_count() > 0:
		check_for_crash(velocity_before_collision)
		if get_parent().current_state.name != "bike": 
			return
	
	# 4. Jump Bail
	if Input.is_action_just_pressed("jump"):
		spawn_bike_prop(false)
		player.velocity.y = player.jump_velocity
		get_parent().change_state("air")

func check_for_crash(pre_hit_velocity: Vector3) -> void:
	for i in player.get_slide_collision_count():
		var collision = player.get_slide_collision(i)
		
		if collision.get_normal().y > 0.5:
			continue
			
		var motion_dir = pre_hit_velocity.normalized()
		var impact = motion_dir.dot(collision.get_normal())
		
		if impact < impact_angle_threshold:
			wipeout(collision.get_normal())
			return

func wipeout(wall_normal: Vector3) -> void:
	print("CRASH! Bike Destroyed.")
	spawn_bike_prop(true)
	player.climb_lockout_timer = 1.0
	player.velocity = (wall_normal * 8.0) + (Vector3.UP * 5.0)
	
	# TODO: Apply time penalty
	
	get_parent().change_state("air")

func spawn_bike_prop(is_broken: bool) -> void:
	var new_bike = BIKE_SCENE.instantiate()
	get_tree().current_scene.add_child(new_bike)
	
	var forward_vec = -player.global_transform.basis.z
	var used_distance = spawn_distance if not is_broken else -0.5
	
	# 1. Calculate the X/Z position (Horizontal only)
	var spawn_pos = player.global_position + (forward_vec * used_distance)
	
	# 2. SNAP TO FLOOR LOGIC
	# We cast a ray from slightly above the player DOWNWARDS to find the floor.
	# This ensures the bike sits on the ground even if the player is in the air.
	var space_state = player.get_world_3d().direct_space_state
	# Start 1m above player center to clear small bumps
	var ray_start = spawn_pos + Vector3(0, 1.0, 0) 
	# End 5m below player (should cover most crash heights)
	var ray_end = spawn_pos + Vector3(0, -5.0, 0) 
	
	var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	# Ensure the ray doesn't accidentally hit the player itself
	query.exclude = [player.get_rid()] 
	
	var result = space_state.intersect_ray(query)
	
	if result:
		# If we hit ground, place bike there + half its height so it sits on top
		spawn_pos.y = result.position.y + bike_half_height
	else:
		# Fallback: If ray hits nothing (void), just use player height - offset
		spawn_pos.y -= 0.5
	
	new_bike.global_position = spawn_pos
	new_bike.global_rotation.y = player.global_rotation.y
	
	if is_broken:
		new_bike.rotation.z = deg_to_rad(90) 
		new_bike.rotation.x = deg_to_rad(randf_range(-20, 20))
		if new_bike.has_node("InteractionZone"):
			new_bike.get_node("InteractionZone").queue_free()
		var mesh = new_bike.get_node_or_null("MeshInstance3D")
		if mesh:
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color.BLACK
			mesh.material_override = mat
