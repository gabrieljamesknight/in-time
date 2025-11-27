class_name TrafficManager
extends Node

# -- CONFIG --
@export var car_scene: PackedScene
@export var traffic_paths: Array[Path3D] # Drag your road paths here
@export var density: float = 20.0 # Meters between cars (approx)
@export var speed_variance: float = 5.0

func _ready() -> void:
	spawn_traffic()

func spawn_traffic() -> void:
	if not car_scene:
		print("TrafficManager Error: No Car Scene assigned!")
		return

	for path in traffic_paths:
		_populate_path(path)

func _populate_path(path: Path3D) -> void:
	var path_length = path.curve.get_baked_length()
	# Calculate how many cars fit on this road based on density
	var car_count = int(path_length / density)
	
	# Determine the step (progress ratio) between cars
	# e.g., if we want 5 cars, we place them at 0.0, 0.2, 0.4, etc.
	var step = 1.0 / float(max(1, car_count))
	
	for i in range(car_count):
		var car_instance = car_scene.instantiate()
		
		# In your specific setup, TrafficCar extends PathFollow3D [cite: 33]
		# So we add it directly as a child of the Path3D
		path.add_child(car_instance)
		
		# Set position on the curve
		# We add a random offset so rows of cars don't look like synchronized swimmers
		var random_offset = randf_range(-0.05, 0.05)
		car_instance.progress_ratio = wrapf((i * step) + random_offset, 0.0, 1.0)
		
		# Apply Speed Variance (The Pants Principle: Simple math = organic feel)
		if "speed" in car_instance:
			# Base speed is usually set in the prefab, we just tweak it
			car_instance.speed += randf_range(-speed_variance, speed_variance)
			
		# Toggle Loop to TRUE because these are background ambient cars
		car_instance.loop = true
