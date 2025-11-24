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
# Added reference for visual tilting
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
	
	# If we are on a bike, we trigger the specific bike wipeout logic
	if state_machine.current_state.name.to_lower() == "bike":
		# We assume the Bike state has a public 'wipeout' method
		state_machine.current_state.wipeout(hit_normal)
	else:
		# Standard foot-traffic hit (Knockback + Air State)
		velocity = hit_normal * force
		velocity.y = 5.0 # Pop them in the air slightly
		state_machine.change_state("air")
		
		# TODO: Add Time Penalty here later
