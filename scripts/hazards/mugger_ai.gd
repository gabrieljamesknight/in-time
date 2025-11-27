class_name MuggerAI
extends CharacterBody3D

# -- CONFIG --
@export_group("Movement")
@export var movement_speed: float = 7.0 
@export var flee_speed: float = 12.0 # Will be overwritten on mug event
@export var rotation_speed: float = 10.0

@export_group("Behavior")
@export var leash_distance: float = 15.0 
@export var chase_patience: float = 2.0

# -- COMPONENTS --
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var mesh: MeshInstance3D = $MeshInstance3D

# -- STATE --
enum AIState { IDLE, CHASE, FLEE, RETURNING }
var current_state: AIState = AIState.IDLE
var target: Node3D = null

# -- LOGIC VARS --
var start_position: Vector3
var patience_timer: float = 0.0
var path_update_timer: float = 0.0
var flee_timer: float = 0.0 # Tracks how long we've been running away
const PATH_UPDATE_INTERVAL: float = 0.1 

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	start_position = global_position
	
	nav_agent.avoidance_enabled = false
	nav_agent.path_desired_distance = 1.0 
	nav_agent.target_desired_distance = 1.0
	
	var zone = get_node_or_null("DetectionZone")
	if zone:
		if not zone.body_entered.is_connected(_on_detection_zone_entered):
			zone.body_entered.connect(_on_detection_zone_entered)
	
	await get_tree().physics_frame

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	match current_state:
		AIState.IDLE:
			velocity.x = move_toward(velocity.x, 0, movement_speed * delta)
			velocity.z = move_toward(velocity.z, 0, movement_speed * delta)
			move_and_slide()
			
		AIState.CHASE:
			process_chase(delta)
			
		AIState.FLEE:
			process_flee(delta)
			
		AIState.RETURNING:
			process_return(delta)

func process_chase(delta: float) -> void:
	if not target:
		current_state = AIState.RETURNING
		return

	# Leash Logic
	var dist_from_home = target.global_position.distance_to(start_position)
	if dist_from_home > leash_distance:
		patience_timer -= delta
		if patience_timer <= 0:
			abandon_chase()
			return
	else:
		patience_timer = chase_patience

	# Pathfinding
	path_update_timer -= delta
	if path_update_timer <= 0:
		nav_agent.target_position = target.global_position
		path_update_timer = PATH_UPDATE_INTERVAL

	if nav_agent.is_navigation_finished():
		return

	move_along_path(movement_speed, delta)
	
	if global_position.distance_squared_to(target.global_position) < (1.5 * 1.5):
		mug_player()

func process_flee(delta: float) -> void:
	# 1. Count down the life timer
	flee_timer -= delta
	
	if flee_timer <= 0:
		queue_free()
		return
		
	# 2. Move
	move_along_path(flee_speed, delta)
	
	# 3. Wall Check (The 1.5s Rule)
	# move_along_path calls move_and_slide, so is_on_wall() is fresh
	if is_on_wall():
		# If we hit a wall and have MORE than 1.5s left, snap it down to 1.5s
		if flee_timer > 1.5:
			print("Mugger hit wall! Despawning in 1.5s")
			flee_timer = 1.5

func process_return(delta: float) -> void:
	if global_position.distance_to(start_position) < 1.0:
		current_state = AIState.IDLE
		return
	
	if path_update_timer <= 0:
		nav_agent.target_position = start_position
		path_update_timer = 1.0 
		
	path_update_timer -= delta
	move_along_path(movement_speed * 0.5, delta)

func abandon_chase() -> void:
	print("Mugger: Too far from home. Returning.")
	target = null
	current_state = AIState.RETURNING
	path_update_timer = 0.0 

func move_along_path(speed: float, delta: float) -> void:
	var current_loc = global_position
	var next_loc = nav_agent.get_next_path_position()
	
	var current_flat = Vector3(current_loc.x, 0, current_loc.z)
	var next_flat = Vector3(next_loc.x, 0, next_loc.z)
	
	var direction = (next_flat - current_flat).normalized()
	
	if direction != Vector3.ZERO:
		var target_rotation = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, rotation_speed * delta)
	
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	move_and_slide()

func mug_player() -> void:
	MissionManager.apply_penalty(MissionManager.time_penalty_mugged)
	
	if target and target.has_method("apply_hit"):
		var knock_dir = (target.global_position - global_position).normalized()
		knock_dir.y = 0.5
		target.apply_hit(knock_dir, 15.0)
	
	# Visual Flash
	var tween = get_tree().create_tween()
	tween.tween_property(mesh, "scale", Vector3(1.5, 0.5, 1.5), 0.1)
	tween.tween_property(mesh, "scale", Vector3(1, 1, 1), 0.2)
	
	# -- FLEE SETUP --
	# Double the current movement speed
	flee_speed = movement_speed * 2.0
	# Set the life timer to 3 seconds
	flee_timer = 3.0
	
	current_state = AIState.FLEE
	pick_flee_destination()

func pick_flee_destination() -> void:
	var random_dir = Vector3(randf() - 0.5, 0, randf() - 0.5).normalized()
	var flee_target = global_position + (random_dir * 25.0)
	nav_agent.target_position = flee_target

func _on_detection_zone_entered(body: Node3D) -> void:
	if body.name == "Player" and current_state != AIState.FLEE:
		if current_state == AIState.IDLE or current_state == AIState.RETURNING:
			target = body
			patience_timer = chase_patience
			current_state = AIState.CHASE
