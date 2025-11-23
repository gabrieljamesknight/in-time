extends State

@export var climb_speed = 4.0
@export var climb_friction = 10.0

const WALL_HUG_SPEED = 2.0

var is_mantling = false
var sticky_descent = false 
var last_wall_normal = Vector3.ZERO 

func enter() -> void:
	print("State: Climbing")
	is_mantling = false
	player.velocity.x = 0
	player.velocity.z = 0
	
	if player.wall_detector.is_colliding():
		last_wall_normal = player.wall_detector.get_collision_normal()
	else:
		last_wall_normal = -player.transform.basis.z

func exit() -> void:
	sticky_descent = false 

func force_descent_mode() -> void:
	sticky_descent = true

func physics_update(delta: float) -> void:
	if is_mantling:
		return

	# -- 1. STICKY MODE MANAGEMENT --
	var input_vector = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	if sticky_descent and input_vector.length() == 0:
		sticky_descent = false
	
	var input_axis = Input.get_axis("move_backward", "move_forward")

	# -- 2. FLOOR CHECK (UPDATED) --
	if player.is_on_floor():
		if sticky_descent:
			# TRIGGER THE INPUT LOCK
			player.req_input_release = true
			get_parent().change_state("idle")
			return
		
		if input_axis > 0:
			pass 
		else:
			get_parent().change_state("idle")
			return

	# -- 3. SMART WALL DETECTION --
	var is_wall_valid = false
	var current_normal = last_wall_normal 
	
	if player.wall_detector.is_colliding():
		is_wall_valid = true
		current_normal = player.wall_detector.get_collision_normal()
		last_wall_normal = current_normal
	else:
		var space_state = player.get_world_3d().direct_space_state
		var ray_dir = -last_wall_normal
		var from_pos = player.global_position + Vector3(0, 0.5, 0)
		var to_pos = from_pos + (ray_dir * 1.0)
		var query = PhysicsRayQueryParameters3D.create(from_pos, to_pos)
		query.exclude = [player.get_rid()]
		var result = space_state.intersect_ray(query)
		if result:
			is_wall_valid = true

	# -- 4. MANTLE CHECK --
	if not sticky_descent and not is_wall_valid:
		if input_axis > 0:
			start_mantle()
			return
		else:
			get_parent().change_state("air")
			return

	# -- 5. VALIDITY CHECK --
	if not is_wall_valid:
		get_parent().change_state("air")
		return

	# -- 6. WALL HUG --
	var push_dir = -current_normal
	player.velocity.x = push_dir.x * WALL_HUG_SPEED
	player.velocity.z = push_dir.z * WALL_HUG_SPEED

	# -- 7. VERTICAL MOVEMENT --
	if sticky_descent:
		player.velocity.y = move_toward(player.velocity.y, -climb_speed, climb_speed * delta)
	else:
		if input_axis > 0:
			player.velocity.y = move_toward(player.velocity.y, climb_speed, climb_speed * delta)
		elif input_axis < 0:
			player.velocity.y = move_toward(player.velocity.y, -climb_speed, climb_speed * delta)
		else:
			player.velocity.y = move_toward(player.velocity.y, 0, climb_friction * delta)

	# -- 8. DISMOUNT --
	if Input.is_action_just_pressed("jump"):
		player.velocity = (current_normal * 6.0)
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
