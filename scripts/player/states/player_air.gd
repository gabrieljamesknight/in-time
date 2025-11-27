extends State

const LEDGE_GRAB_WINDOW = 0.25

# -- FALL DAMAGE SETTINGS --
# -13.0 = Sprained Ankle (Time Penalty)
# -19.0 = Instant Death (Mission Fail)
const HARD_LANDING_THRESHOLD = -13.0 
const FATAL_DROP_THRESHOLD = -19.0

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
		if player.velocity.y < 0 and player.climb_lockout_timer <= 0:
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

	# -- CAPTURE VELOCITY BEFORE COLLISION --
	var vertical_speed_at_impact = player.velocity.y

	player.move_and_slide()

	# 5. Land Logic
	if player.is_on_floor():
		handle_landing(vertical_speed_at_impact)

func handle_landing(impact_speed: float) -> void:
	print("Landed with speed: ", impact_speed)
	
	if impact_speed < FATAL_DROP_THRESHOLD:
		print("FATAL DROP! (Speed: ", impact_speed, " < ", FATAL_DROP_THRESHOLD, ")")
		player.die("Fell to death")
		return
		
	elif impact_speed < HARD_LANDING_THRESHOLD:
		print("CRUNCH! Hard landing. (Speed: ", impact_speed, " < ", HARD_LANDING_THRESHOLD, ")")
		MissionManager.apply_penalty(MissionManager.time_penalty_hard_land)
		
		# Punish momentum
		player.velocity.x = 0
		player.velocity.z = 0
		
		get_parent().change_state("idle")
		
	else:
		get_parent().change_state("idle")

func check_for_ledge_snap() -> void:
	var vel_horizontal = Vector3(player.velocity.x, 0, player.velocity.z)
	var check_dir = -vel_horizontal.normalized()
	
	if vel_horizontal.length() < 0.1:
		check_dir = -player.transform.basis.z 

	var space_state = player.get_world_3d().direct_space_state
	var from_pos = player.global_position
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
	
	var diff = player.global_position - hit_pos
	var flat_normal = Vector3(diff.x, 0, diff.z).normalized()
	
	if flat_normal.is_zero_approx():
		flat_normal = Vector3(wall_normal.x, 0, wall_normal.z).normalized()
		if flat_normal.is_zero_approx():
			flat_normal = -player.basis.z
	
	var target_basis = Basis.looking_at(-flat_normal, Vector3.UP)
	tween.tween_property(player, "basis", target_basis, 0.15)
	
	var snap_pos = hit_pos + (flat_normal * 0.6)
	snap_pos.y = hit_pos.y - 1.25 
	
	tween.tween_property(player, "global_position", snap_pos, 0.15)
	
	tween.chain().tween_callback(func(): 
		var climb_state = get_parent().get_node_or_null("Climb")
		if climb_state:
			climb_state.force_descent_mode()
		
		is_snapping = false
		get_parent().change_state("climb")
	)
