extends State

func enter() -> void:
	# Kill momentum when entering Idle so we don't slide
	player.velocity.x = 0
	player.velocity.z = 0

func physics_update(_delta: float) -> void:
	# 1. Transition: Air (Falling)
	if not player.is_on_floor():
		get_parent().change_state("air")
		return

	# 2. Transition: Jump
	if Input.is_action_just_pressed("jump"):
		player.velocity.y = player.jump_velocity
		get_parent().change_state("air")
		return

	# 3. Transition: Bike (MOUNT) - UPDATED LOGIC
	if Input.is_action_just_pressed("interact"):
		# Check if we are actually standing in a zone (variable set by the InteractiveBike)
		if player.current_interactable != null:
			
			# Optional: Verify it has the method to avoid crashes
			if player.current_interactable.has_method("interact"):
				player.current_interactable.interact() # Destroys the world object
				
				# Clear the reference so we don't hold onto a deleted object
				player.current_interactable = null
				
				# Switch player to Bike physics
				get_parent().change_state("bike")
				return

	# 4. Transition: Run
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	if input_dir.length() > 0:
		get_parent().change_state("run")
