class_name TrafficCar
extends PathFollow3D

@export var speed: float = 15.0
@onready var area: Area3D = $Area3D

func _ready() -> void:
	# Ensure the Area monitor is set up
	if area:
		if not area.body_entered.is_connected(_on_body_entered):
			area.body_entered.connect(_on_body_entered)
			
	# [NEW] Randomize the mesh color slightly for visual variety (Low Scope Art)
	var mesh_instance = get_node_or_null("MeshInstance3D")
	if mesh_instance:
		# Create a new unique material so we don't change ALL cars
		var new_mat = StandardMaterial3D.new()
		new_mat.albedo_color = Color(randf(), randf(), randf()) 
		mesh_instance.material_override = new_mat

func _physics_process(delta: float) -> void:
	progress += speed * delta
	# Loop handling is built-in to PathFollow3D, no extra code needed here
	# unless you want to delete cars at the end (which we don't for ambient traffic).

func _on_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		var hit_dir = (body.global_position - global_position).normalized()
		hit_dir.y = 0.2 
		
		if body.has_method("apply_hit"):
			body.apply_hit(hit_dir, 20.0)
