extends CharacterBody3D

# -- CONFIGURATION --
@export var speed = 5.0
@export var jump_velocity = 4.5
@export var sensitivity = 0.01

# Gravity from Project Settings [cite: 3]
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# -- COMPONENTS --
@onready var cam_origin = $CamOrigin
@onready var state_machine = $StateMachine

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# Initialize FSM passing 'self' as the player reference
	state_machine.init(self)

func _unhandled_input(event):
	# Camera logic stays here as it is independent of movement state
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * sensitivity)
		cam_origin.rotate_x(-event.relative.y * sensitivity)
		cam_origin.rotation.x = clamp(cam_origin.rotation.x, deg_to_rad(-45), deg_to_rad(45))
		
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
		
	if Input.is_action_just_pressed("interact"): # Press E (or your interact key)
		# Only toggle if we are on the floor for now
		if is_on_floor():
			state_machine.change_state("bike")
