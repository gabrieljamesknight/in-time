extends CharacterBody3D

# -- CONFIGURATION --
@export var speed = 5.0
@export var jump_velocity = 4.5
@export var sensitivity = 0.01

# Gravity from Project Settings
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Shared Variables
var current_interactable: Node = null
var climb_lockout_timer: float = 0.0 # <--- NEW: Blocks climbing when > 0

# -- COMPONENTS --
@onready var cam_origin = $CamOrigin
@onready var state_machine = $StateMachine
@onready var wall_detector = $WallDetector

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
