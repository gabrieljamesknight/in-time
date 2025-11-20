extends State

func physics_update(_delta: float) -> void:
	# Transition: Air / Falling
	if not player.is_on_floor():
		get_parent().change_state("air")
		return

	# Transition: Jump
	if Input.is_action_just_pressed("jump"):
		player.velocity.y = player.jump_velocity
		get_parent().change_state("air")
		return

	# Movement Logic
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		player.velocity.x = direction.x * player.speed
		player.velocity.z = direction.z * player.speed
	else:
		# Transition: Idle
		get_parent().change_state("idle")
	
	player.move_and_slide()
