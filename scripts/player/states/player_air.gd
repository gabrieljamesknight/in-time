extends State

func physics_update(delta: float) -> void:
	# 1. Climb Check (Updated with Lockout)
	# We only climb if the timer is 0
	if player.climb_lockout_timer <= 0 and player.wall_detector.is_colliding():
		var collider = player.wall_detector.get_collider()
		if collider.is_in_group("climbable") and Input.is_action_pressed("move_forward"):
			get_parent().change_state("climb")
			return
	
	# 2. Gravity
	player.velocity.y -= player.gravity * delta

	# 3. Air Control
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		player.velocity.x = move_toward(player.velocity.x, direction.x * player.speed, player.speed * delta)
		player.velocity.z = move_toward(player.velocity.z, direction.z * player.speed, player.speed * delta)

	player.move_and_slide()

	# 4. Land
	if player.is_on_floor():
		get_parent().change_state("idle")
