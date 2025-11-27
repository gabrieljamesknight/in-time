class_name MuggerAI
extends CharacterBody3D

# -- CONFIG --
@export var movement_speed: float = 7.0 
@export var detection_range: float = 10.0
@export var catch_cooldown: float = 3.0
@export var rotation_speed: float = 10.0 # New: Controls how smooth he turns

# -- COMPONENTS --
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var mesh: MeshInstance3D = $MeshInstance3D

# -- STATE --
var target: Node3D = null
var is_active: bool = true
var cooldown_timer: float = 0.0

# -- PATHFINDING THROTTLE --
var path_update_timer: float = 0.0
const PATH_UPDATE_INTERVAL: float = 0.1 # Update path only every 0.1s

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	nav_agent.avoidance_enabled = false
	nav_agent.path_desired_distance = 1.0 # Increased slightly to stop jitter near nodes
	nav_agent.target_desired_distance = 1.0
	
	var zone = get_node_or_null("DetectionZone")
	if zone:
		if not zone.body_entered.is_connected(_on_detection_zone_entered):
			zone.body_entered.connect(_on_detection_zone_entered)
		if not zone.body_exited.is_connected(_on_detection_zone_exited):
			zone.body_exited.connect(_on_detection_zone_exited)
	
	await get_tree().physics_frame

func _physics_process(delta: float) -> void:
	# 1. Apply Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# 2. Cooldown check
	if cooldown_timer > 0:
		cooldown_timer -= delta
		move_and_slide()
		return 

	# 3. Chase Logic
	if target and is_active:
		# -- THROTTLED PATH UPDATES --
		# Only ask the map for a new path occasionally to prevent "Path Panic"
		path_update_timer -= delta
		if path_update_timer <= 0:
			nav_agent.target_position = target.global_position
			path_update_timer = PATH_UPDATE_INTERVAL

		# Don't move if we are calculating or close enough
		if nav_agent.is_navigation_finished():
			return

		var current_loc = global_position
		var next_loc = nav_agent.get_next_path_position()
		
		# Flatten vectors (Ignore Y)
		var current_flat = Vector3(current_loc.x, 0, current_loc.z)
		var next_flat = Vector3(next_loc.x, 0, next_loc.z)
		
		# Calculate Move Direction
		var direction = (next_flat - current_flat).normalized()
		
		# -- SMOOTH ROTATION --
		# Instead of look_at(), we smoothly rotate the body towards the direction
		if direction != Vector3.ZERO:
			var target_rotation = atan2(target.global_position.x - global_position.x, target.global_position.z - global_position.z)
			rotation.y = lerp_angle(rotation.y, target_rotation, rotation_speed * delta)
		
		# Apply Velocity
		velocity.x = direction.x * movement_speed
		velocity.z = direction.z * movement_speed
		
		move_and_slide()
		
		# Catch Check (Using Distance Squared is faster)
		if global_position.distance_squared_to(target.global_position) < (1.5 * 1.5):
			attempt_mugging()
			
	else:
		# Stop smoothly
		velocity.x = move_toward(velocity.x, 0, movement_speed * delta)
		velocity.z = move_toward(velocity.z, 0, movement_speed * delta)
		move_and_slide()

func attempt_mugging() -> void:
	print("MUGGED!")
	MissionManager.apply_penalty(MissionManager.time_penalty_mugged)
	
	if target.has_method("apply_hit"):
		var knock_dir = (target.global_position - global_position).normalized()
		knock_dir.y = 0.5
		target.apply_hit(knock_dir, 15.0)
	
	cooldown_timer = catch_cooldown
	is_active = false 
	
	# Visual "Squash" effect
	var tween = get_tree().create_tween()
	tween.tween_property(mesh, "scale", Vector3(1.5, 0.5, 1.5), 0.1)
	tween.tween_property(mesh, "scale", Vector3(1, 1, 1), 0.2)
	
	await get_tree().create_timer(catch_cooldown).timeout
	is_active = true

func _on_detection_zone_entered(body: Node3D) -> void:
	if body.name == "Player":
		target = body

func _on_detection_zone_exited(body: Node3D) -> void:
	if body == target:
		target = null
