extends State

func enter() -> void:
	player.velocity.x = 0
	player.velocity.z = 0

func physics_update(_delta: float) -> void:
	# Transition: Air
	if not player.is_on_floor():
		get_parent().change_state("air")
		return

	# Transition: Jump
	if Input.is_action_just_pressed("jump"):
		player.velocity.y = player.jump_velocity # <--- ADD THIS LINE
		get_parent().change_state("air")
		return

	# Transition: Run
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward") # [cite: 5]
	if input_dir.length() > 0:
		get_parent().change_state("run")
