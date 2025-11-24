extends State

const BIKE_SCENE = preload("res://scenes/interactables/interactive_bike.tscn")

# -- ARCADE BIKE SETTINGS --
var max_speed = 22.0          
var acceleration = 15.0       
var braking = 20.0            
var coast_friction = 5.0      
var turn_speed = 2.0          

# -- TRACTION --
var traction = 4.0 

# -- VISUALS --
var lean_amount = 0.0
var max_lean = 0.3 

# -- WIPEOUT SETTINGS --
var crash_speed_threshold = 12.0 
var impact_angle_threshold = -0.5 # Forgiving angle (0.0 is 90 deg, -1.0 is head on)

# -- SPAWN SETTINGS --
var spawn_distance = 1.5 
var bike_half_height = 0.5 
var dismount_cooldown = 0.2

# -- TWEEN STORAGE --
var mount_tween: Tween

func enter() -> void:
	print("State: Bike Mode Activated")
	dismount_cooldown = 0.2
	
	# Boost on enter
	player.velocity += -player.transform.basis.z * 5.0
	
	# Trigger the Visuals
	animate_mount(true)

func exit() -> void:
	# Ensure we reset when leaving this state cleanly
	animate_mount(false)

func physics_update(delta: float) -> void:
	# 1. Cooldown
	if dismount_cooldown > 0:
		dismount_cooldown -= delta
		
	# 2. Manual Dismount
	if dismount_cooldown <= 0 and Input.is_action_just_pressed("interact"):
		spawn_bike_prop(false)
		get_parent().change_state("idle")
		return
	
	# -- GRAVITY --
	if not player.is_on_floor():
		player.velocity.y -= player.gravity * delta

	# -- STEERING --
	var turn_input = Input.get_axis("move_right", "move_left") 
	var speed_ratio = clamp(player.velocity.length() / 5.0, 0.0, 1.0)
	
	if turn_input != 0:
		player.rotate_y(turn_input * turn_speed * speed_ratio * delta)
		
	# -- ACCELERATION --
	var throttle = Input.get_axis("move_backward", "move_forward")
	var forward_dir = -player.transform.basis.z 
	var current_forward_speed = player.velocity.dot(forward_dir)
	
	if throttle > 0:
		if current_forward_speed < max_speed:
			player.velocity += forward_dir * acceleration * delta
	elif throttle < 0:
		player.velocity += forward_dir * braking * throttle * delta
	else:
		player.velocity = player.velocity.move_toward(Vector3.ZERO, coast_friction * delta)

	# -- TRACTION --
	var right_dir = player.transform.basis.x
	var lateral_velocity = right_dir * player.velocity.dot(right_dir)
	player.velocity -= lateral_velocity * traction * delta
	
	# -- VISUALS: LEANING --
	var target_lean = turn_input * max_lean * speed_ratio
	
	lean_amount = move_toward(lean_amount, target_lean, delta * 2.0)
	
	if player.has_node("MeshInstance3D"):
		player.get_node("MeshInstance3D").rotation.z = lean_amount
		if player.has_node("CamOrigin"):
			player.get_node("CamOrigin").rotation.z = lean_amount * 0.5
	
	# -- MOVE --
	# Capture velocity BEFORE physics resolution stops us
	var velocity_before_collision = player.velocity
	
	player.move_and_slide()
	
	# -- CRASH LOGIC --
	# FIX: Use velocity_before_collision.length() instead of get_real_velocity()
	# Because if we hit a wall, real_velocity is now 0!
	if velocity_before_collision.length() > crash_speed_threshold and player.get_slide_collision_count() > 0:
		check_for_crash(velocity_before_collision)
		# Safety check: if we crashed, we aren't in bike state anymore
		if get_parent().current_state != self: 
			return

	# -- JUMP BAIL --
	if Input.is_action_just_pressed("jump"):
		spawn_bike_prop(false)
		player.velocity.y = player.jump_velocity
		get_parent().change_state("air")


# --- VISUAL TWEENING SECTION ---

func animate_mount(is_mounting: bool) -> void:
	if mount_tween:
		mount_tween.kill()
	
	mount_tween = get_tree().create_tween()
	mount_tween.set_parallel(true)
	mount_tween.set_trans(Tween.TRANS_BACK)
	mount_tween.set_ease(Tween.EASE_OUT)
	
	var cam_origin = player.get_node_or_null("CamOrigin")
	var mesh = player.get_node_or_null("MeshInstance3D")
	
	if is_mounting:
		# LOWER CamOrigin (Crouch effect)
		if cam_origin: 
			mount_tween.tween_property(cam_origin, "position:y", -0.4, 0.3)
		# TILT Mesh forward
		if mesh:
			mount_tween.tween_property(mesh, "rotation:x", deg_to_rad(-25), 0.3)
			mount_tween.tween_property(mesh, "position:y", -0.2, 0.3)
	else:
		# RESET CamOrigin to 0.0
		if cam_origin: 
			mount_tween.tween_property(cam_origin, "position:y", 0.0, 0.2)
			mount_tween.tween_property(cam_origin, "rotation:z", 0.0, 0.2)
		# RESET Mesh
		if mesh:
			mount_tween.tween_property(mesh, "rotation:x", 0.0, 0.2)
			mount_tween.tween_property(mesh, "rotation:z", 0.0, 0.2) 
			mount_tween.tween_property(mesh, "position:y", 0.0, 0.2)

func check_for_crash(pre_hit_velocity: Vector3) -> void:
	for i in player.get_slide_collision_count():
		var collision = player.get_slide_collision(i)
		# Ignore floor
		if collision.get_normal().y > 0.5:
			continue
			
		var motion_dir = pre_hit_velocity.normalized()
		var impact = motion_dir.dot(collision.get_normal())
		
		# Impact threshold: -1.0 is head on, 0.0 is glancing
		if impact < impact_angle_threshold:
			wipeout(collision.get_normal())
			return

func wipeout(wall_normal: Vector3) -> void:
	print("CRASH! Bike Destroyed.")
	spawn_bike_prop(true)
	
	# Lock climbing so we don't accidentally grab the wall we just hit
	player.climb_lockout_timer = 1.0
	
	# -- CALCULATE KNOCKBACK --
	# wall_normal: Points directly away from the wall.
	# We increase the horizontal force (8.0 -> 15.0) for a harder impact.
	# We decrease the vertical force (5.0 -> 1.5) just to clear ground friction.
	player.velocity = (wall_normal * 15.0) + (Vector3.UP * 1.5)
	
	get_parent().change_state("air")

func spawn_bike_prop(is_broken: bool) -> void:
	var new_bike = BIKE_SCENE.instantiate()
	get_tree().current_scene.add_child(new_bike)
	var forward_vec = -player.global_transform.basis.z
	var used_distance = spawn_distance if not is_broken else -0.5
	var spawn_pos = player.global_position + (forward_vec * used_distance)
	var space_state = player.get_world_3d().direct_space_state
	var ray_start = spawn_pos + Vector3(0, 1.0, 0) 
	var ray_end = spawn_pos + Vector3(0, -5.0, 0) 
	var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	query.exclude = [player.get_rid()] 
	var result = space_state.intersect_ray(query)
	if result:
		spawn_pos.y = result.position.y + bike_half_height
	else:
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
