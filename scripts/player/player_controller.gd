extends CharacterBody3D

# -- CONFIGURATION --
@export_group("Movement")
@export var walk_speed = 5.0
@export var sprint_speed = 9.0
@export var accel = 10.0
@export var jump_velocity = 4.5
@export var sensitivity = 0.005

# Current active speed (modified by states)
var speed = 5.0

# Gravity from Project Settings
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Shared Variables
var current_interactable: Node = null
var climb_lockout_timer: float = 0.0 
var req_input_release: bool = false 

# -- COMPONENTS --
@onready var cam_origin = $CamOrigin
@onready var state_machine = $StateMachine
@onready var wall_detector = $WallDetector
@onready var mesh = $MeshInstance3D

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	state_machine.init(self)

func _physics_process(delta: float) -> void:
	# Count down the lockout timer
	if climb_lockout_timer > 0:
		climb_lockout_timer -= delta

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * sensitivity)
		cam_origin.rotate_x(-event.relative.y * sensitivity)
		cam_origin.rotation.x = clamp(cam_origin.rotation.x, deg_to_rad(-45), deg_to_rad(45))
		
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
		
func apply_hit(hit_normal: Vector3, force: float = 10.0) -> void:
	print("Player Hit!")
	
	if state_machine.current_state.name.to_lower() == "bike":
		state_machine.current_state.wipeout(hit_normal)
	else:
		velocity = hit_normal * force
		velocity.y = 5.0 
		state_machine.change_state("air")
		MissionManager.apply_penalty(MissionManager.time_penalty_hit)

func die(reason: String) -> void:
	print("PLAYER DIED: ", reason)
	
	# 1. LOCK CONTROLS
	# Stop physics processing so we can't move
	set_physics_process(false)
	set_process_unhandled_input(false)
	
	# 2. KILL STATE MACHINE
	# This prevents the 'Run' or 'Idle' state from trying to stand us back up
	state_machine.set_physics_process(false)
	state_machine.set_process(false)
	
	# 3. VISUAL SPLAT
	if mesh:
		var tween = get_tree().create_tween()
		tween.set_parallel(true)
		tween.set_trans(Tween.TRANS_BOUNCE) # A little bounce when hitting floor
		tween.set_ease(Tween.EASE_OUT)
		
		# Rotate 90 degrees on X axis (Faceplant/Lay flat)
		tween.tween_property(mesh, "rotation:x", deg_to_rad(-90), 0.2)
		
		# Lower the mesh slightly so it looks like it's ON the floor, not floating inside it
		# (Assuming capsule height is 2, center is 0, so -1 is floor. We go to -0.9)
		tween.tween_property(mesh, "position:y", -0.9, 0.2)
	
	# 4. REPORT FAILURE
	MissionManager.fail_mission(reason)
