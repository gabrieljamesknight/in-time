### scripts/player/states/player_climb.gd
extends State

@export var climb_speed = 4.0
@export var climb_friction = 10.0

func enter() -> void:
	print("State: Climbing")
	# Kill horizontal momentum for a snappy stick
	player.velocity.x = 0
	player.velocity.z = 0

func physics_update(delta: float) -> void:
	# 1. Check for Wall
	# We assume the player script has a reference to the RayCast
	if not player.wall_detector.is_colliding():
		get_parent().change_state("air")
		return

	# 2. Check Validity (Groups)
	var collider = player.wall_detector.get_collider()
	if not collider.is_in_group("climbable"):
		get_parent().change_state("air")
		return

	# 3. Movement Logic
	# Hold Forward (W) to climb UP
	var input_dir = Input.get_axis("move_backward", "move_forward") # Returns 1 for Forward
	
	if input_dir > 0:
		# Climb Up
		player.velocity.y = move_toward(player.velocity.y, climb_speed, climb_speed * delta)
	elif input_dir < 0:
		# Climb Down (optional, or just let them fall)
		player.velocity.y = move_toward(player.velocity.y, -climb_speed, climb_speed * delta)
	else:
		# Hold position (Static friction)
		player.velocity.y = move_toward(player.velocity.y, 0, climb_friction * delta)

	# 4. Dismount (Jump off wall)
	if Input.is_action_just_pressed("jump"):
		# Add a little push away from the wall for style
		var wall_normal = player.wall_detector.get_collision_normal()
		player.velocity = (wall_normal * 5.0) # Push back
		player.velocity.y = player.jump_velocity # Push up
		get_parent().change_state("air")
		return

	player.move_and_slide()
