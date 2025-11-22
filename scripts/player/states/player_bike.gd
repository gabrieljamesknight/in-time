extends State

# Preload the interactive bike scene
const BIKE_SCENE = preload("res://scenes/interactables/interactive_bike.tscn")

# -- BIKE SETTINGS --
var bike_speed = 12.0
var acceleration = 4.0
var friction = 2.0 

# -- SPAWN SETTINGS --
# Shortened distance to keep it reachable (1.5m)
var spawn_distance = 1.5 
# Adjusted offset: 
# Player Center is roughly Y=1.0 (relative to floor). 
# Bike Center needs to be Y=0.5 (so bottom touches floor).
# Offset = 1.0 - 0.5 = 0.5
var height_offset = 0.5 

# Cooldown to prevent instant dismounting
var dismount_cooldown = 0.2

func enter() -> void:
	print("State: Bike Mode Activated")
	# RESET cooldown so we don't instantly exit
	dismount_cooldown = 0.2
	
	# Optional: Swap mesh here
	# player.mesh.mesh = load("res://assets/models/bike_player.obj")

func exit() -> void:
	# Optional: Swap back to normal player mesh
	pass

func physics_update(delta: float) -> void:
	# 1. Handle the Cooldown
	if dismount_cooldown > 0:
		dismount_cooldown -= delta
		
	# 2. Dismount Logic (Standard Dismount)
	if dismount_cooldown <= 0 and Input.is_action_just_pressed("interact"):
		spawn_bike_prop()
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
	
	# 3. Dismount Logic (Jump bail)
	if Input.is_action_just_pressed("jump"):
		spawn_bike_prop()
		player.velocity.y = player.jump_velocity
		get_parent().change_state("air")

func spawn_bike_prop() -> void:
	var new_bike = BIKE_SCENE.instantiate()
	get_tree().current_scene.add_child(new_bike)
	
	# 1. Calculate position IN FRONT of player
	var forward_vec = -player.global_transform.basis.z
	var spawn_pos = player.global_position + (forward_vec * spawn_distance)
	
	# 2. Adjust Height
	# Subtract the offset to align bike bottom with floor
	spawn_pos.y -= height_offset
	
	# 3. Apply Transform
	new_bike.global_position = spawn_pos
	new_bike.global_rotation.y = player.global_rotation.y
	
	print("Bike dropped at: ", new_bike.global_position)
