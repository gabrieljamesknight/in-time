class_name TrafficCar
extends PathFollow3D

@export var speed: float = 15.0
# We do not declare 'loop' here because it is a native property of PathFollow3D.
# You can toggle 'Loop' in the Inspector for this node.

# Defines the "Hitbox" for the car
@onready var area: Area3D = $Area3D

func _ready() -> void:
	# Ensure the Area monitor is set up
	if area:
		# Safety check to ensure we don't connect twice
		if not area.body_entered.is_connected(_on_body_entered):
			area.body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	# Move along the path
	progress += speed * delta
	
	# The 'loop' property is built-in. 
	# If Loop is FALSE in the inspector, the car destroys itself at the end of the path.
	# If Loop is TRUE, it automatically wraps around (Godot handles the wrapping).
	if progress_ratio >= 1.0 and not loop:
		queue_free()

func _on_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		# Calculate direction from Car to Player for knockback
		var hit_dir = (body.global_position - global_position).normalized()
		# Flatten Y so they don't get launched into orbit purely by geometry
		hit_dir.y = 0.2 
		
		if body.has_method("apply_hit"):
			# Apply the hit to the player controller
			body.apply_hit(hit_dir, 20.0)
