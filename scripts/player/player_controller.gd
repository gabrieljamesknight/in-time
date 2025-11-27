extends CharacterBody3D

# -- CONFIGURATION --
@export_group("Movement")
@export var walk_speed = 5.0
@export var sprint_speed = 9.0
@export var accel = 10.0
@export var jump_velocity = 4.5
@export var sensitivity = 0.005

@export_group("Camera Juice")
@export var base_fov: float = 75.0
@export var max_fov_boost: float = 20.0 # How much FOV widens at max speed
@export var fov_smooth_speed: float = 5.0
@export var tilt_angle: float = 2.0 # Degrees to roll when strafing
@export var tilt_speed: float = 8.0

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
@onready var camera_3d = $CamOrigin/Camera3D # [NEW] Direct reference to camera
@onready var state_machine = $StateMachine
@onready var wall_detector = $WallDetector
@onready var mesh = $MeshInstance3D

# -- JUICE VARIABLES --
var trauma: float = 0.0 # 0.0 to 1.0 (Shake intensity)
var shake_power: float = 2.0 # How much the camera moves at max trauma
var shake_decay: float = 2.0 # How fast trauma fades

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	state_machine.init(self)
	
	# Ensure camera starts correct
	if camera_3d:
		camera_3d.fov = base_fov

func _physics_process(delta: float) -> void:
	# Count down the lockout timer
	if climb_lockout_timer > 0:
		climb_lockout_timer -= delta
		
	# Process Camera Juice (FOV, Tilt, Shake)
	_process_camera_juice(delta)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * sensitivity)
		cam_origin.rotate_x(-event.relative.y * sensitivity)
		cam_origin.rotation.x = clamp(cam_origin.rotation.x, deg_to_rad(-45), deg_to_rad(45))
		
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
		
func apply_hit(hit_normal: Vector3, force: float = 10.0) -> void:
	print("Player Hit!")
	add_trauma(0.6) # [NEW] Add shake on impact
	
	if state_machine.current_state.name.to_lower() == "bike":
		state_machine.current_state.wipeout(hit_normal)
	else:
		velocity = hit_normal * force
		velocity.y = 5.0 
		state_machine.change_state("air")
		MissionManager.apply_penalty(MissionManager.time_penalty_hit)

func die(reason: String) -> void:
	print("PLAYER DIED: ", reason)
	add_trauma(1.0) # [NEW] Maximum shake on death
	
	# 1. LOCK CONTROLS
	set_physics_process(false)
	set_process_unhandled_input(false)
	
	# 2. KILL STATE MACHINE
	state_machine.set_physics_process(false)
	state_machine.set_process(false)
	
	# 3. VISUAL SPLAT
	if mesh:
		var tween = get_tree().create_tween()
		tween.set_parallel(true)
		tween.set_trans(Tween.TRANS_BOUNCE) 
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(mesh, "rotation:x", deg_to_rad(-90), 0.2)
		tween.tween_property(mesh, "position:y", -0.9, 0.2)
	
	# 4. REPORT FAILURE
	MissionManager.fail_mission(reason)

# --- CAMERA JUICE LOGIC ---

func _process_camera_juice(delta: float) -> void:
	if not camera_3d: return

	# 1. DYNAMIC FOV
	# Based on horizontal velocity speed relative to sprint speed
	var horizontal_vel = Vector3(velocity.x, 0, velocity.z).length()
	# We use 20.0 as a reference "max speed" (roughly bike speed)
	var speed_fraction = clamp(horizontal_vel / 20.0, 0.0, 1.0)
	var target_fov = base_fov + (speed_fraction * max_fov_boost)
	
	camera_3d.fov = lerp(camera_3d.fov, target_fov, fov_smooth_speed * delta)
	
	# 2. STRAFE TILT (Quake Style)
	# Only apply if NOT on bike (Bike has its own lean logic)
	if state_machine.current_state.name.to_lower() != "bike":
		var input_x = Input.get_axis("move_left", "move_right")
		var target_tilt = -input_x * deg_to_rad(tilt_angle)
		camera_3d.rotation.z = lerp(camera_3d.rotation.z, target_tilt, tilt_speed * delta)
	
	# 3. SCREEN SHAKE
	if trauma > 0:
		trauma = max(trauma - (shake_decay * delta), 0.0)
		_shake_camera()

func add_trauma(amount: float) -> void:
	trauma = clamp(trauma + amount, 0.0, 1.0)

func _shake_camera() -> void:
	# Shake uses perlin-like noise or random offsets
	# We square trauma so small hits are subtle, big hits are massive
	var amount = trauma * trauma 
	var offset_x = (randf() * 2.0 - 1.0) * shake_power * amount
	var offset_y = (randf() * 2.0 - 1.0) * shake_power * amount
	
	# Apply locally to the Camera3D, not the CamOrigin (which handles mouse look)
	camera_3d.h_offset = offset_x
	camera_3d.v_offset = offset_y
	# Note: We don't modify rotation.z here to avoid fighting the Strafe Tilt 
	# effectively, but if you want chaos, you can add 'roll' to rotation.z
