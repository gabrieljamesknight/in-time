extends State

const LEDGE_GRAB_WINDOW = 0.25
var ledge_timer: float = 0.0
var is_snapping = false 

func enter() -> void:
	ledge_timer = LEDGE_GRAB_WINDOW
	is_snapping = false

func physics_update(delta: float) -> void:
	if is_snapping:
		return

	# 1. LEDGE GRAB CHECK
	if ledge_timer > 0:
		ledge_timer -= delta
		if player.climb_lockout_timer <= 0:
			check_for_ledge_snap()
	
	# 2. Standard Climb Check
	if player.climb_lockout_timer <= 0 and player.wall_detector.is_colliding():
		var collider = player.wall_detector.get_collider()
		if collider.is_in_group("climbable") and Input.is_action_pressed("move_forward"):
			get_parent().change_state("climb")
			return
	
	# 3. Gravity
	player.velocity.y -= player.gravity * delta

	# 4. Air Control
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		player.velocity.x = move_toward(player.velocity.x, direction.x * player.speed, player.speed * delta)
		player.velocity.z = move_toward(player.velocity.z, direction.z * player.speed, player.speed * delta)

	player.move_and_slide()

	# 5. Land
	if player.is_on_floor():
		get_parent().change_state("idle")

func check_for_ledge_snap() -> void:
	var vel_horizontal = Vector3(player.velocity.x, 0, player.velocity.z)
	var check_dir = -vel_horizontal.normalized()
	
	if vel_horizontal.length() < 0.1:
		check_dir = player.transform.basis.z 

	var space_state = player.get_world_3d().direct_space_state
	var from_pos = player.global_position
	# Heel Check
	var to_pos = from_pos + (check_dir * 1.0) - Vector3(0, 1.5, 0)
	
	var query = PhysicsRayQueryParameters3D.create(from_pos, to_pos)
	query.exclude = [player.get_rid()]
	
	var result = space_state.intersect_ray(query)
	
	if result:
		var collider = result["collider"]
		if collider.is_in_group("climbable"):
			perform_snap_to_wall(result["position"], result["normal"])

func perform_snap_to_wall(hit_pos: Vector3, wall_normal: Vector3) -> void:
	print("Ledge detected! Snapping...")
	is_snapping = true 
	player.velocity = Vector3.ZERO
	
	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	
	# --- FIX: SPATIAL NORMAL CALCULATION ---
	# Instead of trusting the collision normal (which might be UP if we hit the floor),
	# we calculate the vector from the HIT POINT to the PLAYER.
	# This guarantees we find the "Outward" direction relative to the wall geometry.
	var diff = player.global_position - hit_pos
	var flat_normal = Vector3(diff.x, 0, diff.z).normalized()
	
	# Fallback: If we are directly above the hit (rare), use velocity or wall_normal
	if flat_normal.is_zero_approx():
		# Try using the collision normal flattened
		flat_normal = Vector3(wall_normal.x, 0, wall_normal.z).normalized()
		# Absolute fallback
		if flat_normal.is_zero_approx():
			flat_normal = -player.basis.z
	
	# 1. ROTATION
	# Look AT the wall (Negative Flat Normal)
	var target_basis = Basis.looking_at(-flat_normal, Vector3.UP)
	tween.tween_property(player, "basis", target_basis, 0.15)
	
	# 2. POSITION SNAP
	# Push out 0.6m from the exact hit point using our robust normal
	var snap_pos = hit_pos + (flat_normal * 0.6)
	snap_pos.y = hit_pos.y - 1.25 
	
	tween.tween_property(player, "global_position", snap_pos, 0.15)
	
	# 3. CHAIN TRANSITION
	tween.chain().tween_callback(func(): 
		var climb_state = get_parent().get_node_or_null("Climb")
		if climb_state:
			climb_state.force_descent_mode()
		
		is_snapping = false
		get_parent().change_state("climb")
	)
