extends State

@export var climb_speed = 4.0
@export var climb_friction = 10.0

# How hard we push into the wall to ensure the RayCast hits
const WALL_HUG_SPEED = 2.0

# State Flags
var is_mantling = false
var sticky_descent = false # <--- NEW: Forces downward movement if true

func enter() -> void:
	print("State: Climbing")
	is_mantling = false
	# Note: We do NOT reset sticky_descent here, because it is set 
	# by the Air state immediately BEFORE entering this state.
	
	player.velocity.x = 0
	player.velocity.z = 0

func exit() -> void:
	# Clean up flags when leaving the state
	sticky_descent = false 

func force_descent_mode() -> void:
	sticky_descent = true

func physics_update(delta: float) -> void:
	if is_mantling:
		return

	# -- 1. STICKY MODE MANAGEMENT --
	# Check if user has released the keys. If so, disable the override.
	var input_vector = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	if sticky_descent and input_vector.length() == 0:
		sticky_descent = false
	
	var input_axis = Input.get_axis("move_backward", "move_forward")

	# -- 2. FLOOR CHECK --
	if player.is_on_floor():
		# A. If in Sticky Mode: We are holding buttons to go down, and hit floor -> Idle.
		if sticky_descent:
			get_parent().change_state("idle")
			return
			
		# B. Normal Mode:
		# If holding Up (1.0), we want to start climbing from the floor. Pass.
		if input_axis > 0:
			pass 
		# If holding Down/Neutral, we climbed to the bottom. Exit.
		else:
			get_parent().change_state("idle")
			return

	# -- 3. WALL HUG --
	var forward_dir = -player.transform.basis.z
	player.velocity.x = forward_dir.x * WALL_HUG_SPEED
	player.velocity.z = forward_dir.z * WALL_HUG_SPEED

	# -- 4. MANTLE CHECK --
	# (Only valid if we are NOT in sticky descent mode)
	if not sticky_descent and not player.wall_detector.is_colliding():
		if input_axis > 0:
			start_mantle()
			return
		else:
			get_parent().change_state("air")
			return

	# -- 5. VALIDITY CHECK --
	if player.wall_detector.is_colliding():
		var collider = player.wall_detector.get_collider()
		if not collider.is_in_group("climbable"):
			get_parent().change_state("air")
			return
	else:
		# If we lost the wall and didn't mantle, we fall
		get_parent().change_state("air")
		return

	# -- 6. VERTICAL MOVEMENT --
	if sticky_descent:
		# Override: ANY key held means "Climb Down"
		player.velocity.y = move_toward(player.velocity.y, -climb_speed, climb_speed * delta)
	
	else:
		# Standard: W=Up, S=Down
		if input_axis > 0:
			player.velocity.y = move_toward(player.velocity.y, climb_speed, climb_speed * delta)
		elif input_axis < 0:
			player.velocity.y = move_toward(player.velocity.y, -climb_speed, climb_speed * delta)
		else:
			player.velocity.y = move_toward(player.velocity.y, 0, climb_friction * delta)

	# -- 7. DISMOUNT --
	if Input.is_action_just_pressed("jump"):
		var wall_normal = Vector3.BACK # Default fallback
		if player.wall_detector.is_colliding():
			wall_normal = player.wall_detector.get_collision_normal()
			
		player.velocity = (wall_normal * 6.0)
		player.velocity.y = player.jump_velocity
		get_parent().change_state("air")
		return

	player.move_and_slide()

func start_mantle() -> void:
	print("Mantling...")
	is_mantling = true
	
	var start_pos = player.global_position
	var peak_pos = start_pos + Vector3(0, 2.2, 0)
	var forward_vec = -player.transform.basis.z
	var land_pos = peak_pos + (forward_vec * 1.0)
	
	var tween = get_tree().create_tween()
	tween.tween_property(player, "global_position", peak_pos, 0.25).set_trans(Tween.TRANS_SINE)
	tween.tween_property(player, "global_position", land_pos, 0.15).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(finish_mantle)

func finish_mantle() -> void:
	player.velocity = Vector3.ZERO
	if "climb_lockout_timer" in player:
		player.climb_lockout_timer = 0.3
	get_parent().change_state("idle")
