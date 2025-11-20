extends State

func physics_update(delta: float) -> void:
	if player.wall_detector.is_colliding():
		var collider = player.wall_detector.get_collider()
		# Only climb if the wall is in the "climbable" group AND we are holding Forward
		if collider.is_in_group("climbable") and Input.is_action_pressed("move_forward"):
			get_parent().change_state("climb")
			return
	
	# Gravity
	player.velocity.y -= player.gravity * delta

	# Simple Air Control (Quake-lite)
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		# Less control in air (multiply by 0.5 or similar if desired)
		player.velocity.x = move_toward(player.velocity.x, direction.x * player.speed, player.speed * delta)
		player.velocity.z = move_toward(player.velocity.z, direction.z * player.speed, player.speed * delta)

	player.move_and_slide()

	# Transition: Landed
	if player.is_on_floor():
		get_parent().change_state("idle")
