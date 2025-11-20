extends CharacterBody3D

# -- CONFIGURATION --
@export var speed = 5.0
@export var jump_velocity = 4.5
@export var sensitivity = 0.01

# Gravity from Project Settings
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# -- COMPONENTS --
@onready var cam_origin = $CamOrigin
@onready var state_machine = $StateMachine

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# Initialize FSM passing 'self' as the player reference
	state_machine.init(self)

func _unhandled_input(event):
	# Camera logic independent of movement state
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * sensitivity)
		cam_origin.rotate_x(-event.relative.y * sensitivity)
		cam_origin.rotation.x = clamp(cam_origin.rotation.x, deg_to_rad(-45), deg_to_rad(45))
		
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()

	# NOTE: The "Interact" logic has been moved to player_idle.gd
	# to prevents the "Instant Dismount" bug.
