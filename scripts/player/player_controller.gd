extends CharacterBody3D

# Settings
@export var speed = 5.0
@export var jump_velocity = 4.5
@export var sensitivity = 0.01

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var cam_origin = $CamOrigin
@onready var camera = $CamOrigin/Camera3D

func _ready():
	# Capture mouse for look controls
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		# Rotate Player (Y-axis / Left-Right)
		rotate_y(-event.relative.x * sensitivity)
		# Rotate Camera Pivot (X-axis / Up-Down)
		cam_origin.rotate_x(-event.relative.y * sensitivity)
		cam_origin.rotation.x = clamp(cam_origin.rotation.x, deg_to_rad(-45), deg_to_rad(45))
		
	if Input.is_action_just_pressed("ui_cancel"): # "ui_cancel" is mapped to ESC by default
		get_tree().quit()

func _physics_process(delta):
	# Add gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	# Transform input to be relative to the player's facing direction
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()
	
	
