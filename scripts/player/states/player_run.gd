extends State

# -- VISUALS --
const TILT_ANGLE = -15.0 # Degrees to lean forward
const TILT_SPEED = 5.0   # How fast we lean

func enter() -> void:
	pass

func exit() -> void:
	# RESET visuals when leaving Run state (e.g. jumping or stopping)
	# We tween it for smoothness so it doesn't snap instantly
	var tween = get_tree().create_tween()
	tween.tween_property(player.mesh, "rotation_degrees:x", 0.0, 0.2)

func physics_update(delta: float) -> void:
	# 1. Transition: Climb
	if player.wall_detector.is_colliding():
		var collider = player.wall_detector.get_collider()
		if collider.is_in_group("climbable") and Input.is_action_pressed("move_forward"):
			get_parent().change_state("climb")
			return
	
	# 2. Transition: Air / Falling
	if not player.is_on_floor():
		get_parent().change_state("air")
		return

	# 3. Transition: Jump
	if Input.is_action_just_pressed("jump"):
		player.velocity.y = player.jump_velocity
		get_parent().change_state("air")
		return

	# 4. Movement Logic & Sprinting
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# SPRINT LOGIC
	var target_speed = player.walk_speed
	var target_tilt = 0.0
	
	if Input.is_action_pressed("sprint") and input_dir.y < 0: # Only sprint if moving forward
		target_speed = player.sprint_speed
		target_tilt = deg_to_rad(TILT_ANGLE)
	
	# Smoothly interpolate current speed to target speed (Acceleration)
	player.speed = move_toward(player.speed, target_speed, player.accel * delta)
	
	# VISUAL: Apply the forward tilt to the mesh
	# We use lerp to smoothly move the X rotation towards the target
	var current_tilt = player.mesh.rotation.x
	player.mesh.rotation.x = move_toward(current_tilt, target_tilt, TILT_SPEED * delta)
	
	if direction:
		player.velocity.x = direction.x * player.speed
		player.velocity.z = direction.z * player.speed
	else:
		# Transition: Idle
		get_parent().change_state("idle")
	
	player.move_and_slide()
