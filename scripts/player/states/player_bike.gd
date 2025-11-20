extends State

# Bike specific settings
var bike_speed = 12.0
var acceleration = 4.0
var friction = 2.0 # Lower friction = driftier handling

var dismount_cooldown = 0.2

func enter() -> void:
	print("State: Bike Mode Activated")
	# Optional: Here is where you would swap the mesh to a bike model
	# player.mesh.mesh = load("res://path/to/bike.obj")

func exit() -> void:
	# Optional: Swap back to normal player mesh
	pass

func physics_update(delta: float) -> void:
# 1. Handle the Cooldown
	if dismount_cooldown > 0:
		dismount_cooldown -= delta
		
	# 2. Dismount Logic (Only allowed if cooldown is finished)
	if dismount_cooldown <= 0 and Input.is_action_just_pressed("interact"):
		get_parent().change_state("idle")
		return
		
	# Gravity still applies!
	if not player.is_on_floor():
		player.velocity.y -= player.gravity * delta
	
	# Get Input
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		# Accelerate towards top speed (Drift feel)
		player.velocity.x = move_toward(player.velocity.x, direction.x * bike_speed, acceleration * delta)
		player.velocity.z = move_toward(player.velocity.z, direction.z * bike_speed, acceleration * delta)
	else:
		# Decelerate slowly (Coasting)
		player.velocity.x = move_toward(player.velocity.x, 0, friction * delta)
		player.velocity.z = move_toward(player.velocity.z, 0, friction * delta)
	
	player.move_and_slide()
	
	# Dismount Logic (Press Jump to bail out?)
	if Input.is_action_just_pressed("jump"):
		player.velocity.y = player.jump_velocity
		get_parent().change_state("air")
