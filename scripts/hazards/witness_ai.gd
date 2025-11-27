class_name WitnessAI
extends CharacterBody3D

# -- CONFIG --
@export_group("Vision")
@export var vision_range: float = 20.0
@export var vision_angle: float = 160.0 
@export var reaction_delay: float = 0.5

@export_group("Patrol")
@export var patrol_path: Path3D 
@export var start_waypoint_index: int = 0 # [NEW] Which point to go to first
@export var walk_speed: float = 3.0
@export var speed_variance: float = 0.5 # [NEW] Randomize speed slightly
@export var rotation_speed: float = 5.0
@export var waypoint_threshold: float = 1.5

# -- COMPONENTS --
@onready var mesh: MeshInstance3D = $MeshInstance3D

# -- STATE --
var is_alerted: bool = false
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var patrol_points: PackedVector3Array
var current_point_index: int = 0

func _ready() -> void:
	MissionManager.crime_committed.connect(_on_crime_reported)
	
	# [NEW] Apply random speed difference so they don't sync up perfectly
	walk_speed += randf_range(-speed_variance, speed_variance)
	
	if patrol_path:
		var curve = patrol_path.curve
		for i in range(curve.point_count):
			var global_point = patrol_path.to_global(curve.get_point_position(i))
			patrol_points.append(global_point)
			
		# [NEW] Set the starting target based on Inspector value
		if not patrol_points.is_empty():
			# The % operator ensures we don't crash if you type "99" on a path with 4 points
			current_point_index = start_waypoint_index % patrol_points.size()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	if not is_alerted and not patrol_points.is_empty():
		process_patrol(delta)
	else:
		velocity.x = move_toward(velocity.x, 0, walk_speed * delta)
		velocity.z = move_toward(velocity.z, 0, walk_speed * delta)

	move_and_slide()

func process_patrol(delta: float) -> void:
	var target = patrol_points[current_point_index]
	
	var pos_flat = Vector3(global_position.x, 0, global_position.z)
	var target_flat = Vector3(target.x, 0, target.z)
	
	var distance = pos_flat.distance_to(target_flat)
	
	if distance < waypoint_threshold:
		current_point_index = (current_point_index + 1) % patrol_points.size()
	else:
		var direction = (target_flat - pos_flat).normalized()
		var target_rotation = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, rotation_speed * delta)
		
		velocity.x = direction.x * walk_speed
		velocity.z = direction.z * walk_speed

func _on_crime_reported(thief: Node3D) -> void:
	if is_alerted or not is_instance_valid(thief): return
	
	var target_pos = thief.global_position + Vector3(0, 1.0, 0)
	
	# 1. Distance Check
	var dist_sq = global_position.distance_squared_to(target_pos)
	if dist_sq > (vision_range * vision_range): return 
		
	# 2. Angle Check (Flattened)
	var witness_flat = Vector3(global_position.x, 0, global_position.z)
	var target_flat = Vector3(target_pos.x, 0, target_pos.z)
	
	var to_target_flat = (target_flat - witness_flat).normalized()
	var forward_flat = -global_transform.basis.z 
	forward_flat.y = 0
	forward_flat = forward_flat.normalized()
	
	var dot = forward_flat.dot(to_target_flat)
	var angle_threshold = cos(deg_to_rad(vision_angle / 2.0))
	
	if dot < angle_threshold: return 
		
	# 3. Raycast
	var space_state = get_world_3d().direct_space_state
	var origin = global_position + Vector3(0, 1.5, 0)
	var query = PhysicsRayQueryParameters3D.create(origin, target_pos)
	query.exclude = [self.get_rid()] 
	
	var result = space_state.intersect_ray(query)

	# 4. Verification
	if result and result.collider == thief:
		look_at(Vector3(target_pos.x, global_position.y, target_pos.z))
		alert_police()

func alert_police() -> void:
	is_alerted = true
	print("WITNESS: I see you!! Calling Police!")
	
	var tween = get_tree().create_tween()
	tween.tween_property(mesh, "position:y", 0.5, 0.1).set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property(mesh, "position:y", 0.0, 0.1)
	
	MissionManager.apply_penalty(MissionManager.time_penalty_caught_stealing)
