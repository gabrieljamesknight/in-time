extends State

func enter() -> void:
	# Kill momentum when entering Idle so we don't slide
	player.velocity.x = 0
	player.velocity.z = 0

func physics_update(_delta: float) -> void:
	# 0. INPUT LOCKOUT CHECK (The Reset Logic)
	if player.req_input_release:
		var input_vector = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
		if input_vector.length() > 0:
			# User is still holding keys. 
			# Do NOT process movement. Stay in Idle (Velocity 0).
			return
		else:
			# User released keys.
			# Unlock controls.
			player.req_input_release = false
			print("Controls Unlocked")

	# 1. Transition: Air (Falling)
	if not player.is_on_floor():
		get_parent().change_state("air")
		return

	# 2. Transition: Jump
	if Input.is_action_just_pressed("jump"):
		player.velocity.y = player.jump_velocity
		get_parent().change_state("air")
		return

	# 3. Transition: Bike (MOUNT)
	if Input.is_action_just_pressed("interact"):
		if player.current_interactable != null:
			if player.current_interactable.has_method("interact"):
				player.current_interactable.interact()
				player.current_interactable = null
				get_parent().change_state("bike")
				return

	# 4. Transition: Run
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	if input_dir.length() > 0:
		get_parent().change_state("run")
