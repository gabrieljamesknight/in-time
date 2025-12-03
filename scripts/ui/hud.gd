### scripts/ui/hud.gd
extends CanvasLayer

@onready var timer_label: Label = $Control/TimerContainer/VBoxContainer/TimerLabel
@onready var penalty_label: Label = $Control/TimerContainer/VBoxContainer/PenaltyLabel
@onready var status_label: Label = $Control/StatusContainer/StatusLabel
@onready var arrow_icon: Control = $Control/ArrowControl/ArrowIcon 

# TUNING: 180 flips the Left-pointing image to point Right (0 degrees).
@export var icon_rotation_offset: float = 180.0
@export var rotation_speed: float = 25.0 # Increased for responsiveness

# STATE VARIABLES
var is_flashing: bool = false
var flash_tween: Tween 
var penalty_tween: Tween 
var player_ref: Node3D = null

func _ready() -> void:
	MissionManager.time_updated.connect(_on_time_updated)
	MissionManager.mission_started.connect(_on_mission_started)
	MissionManager.mission_failed.connect(_on_mission_failed)
	MissionManager.mission_success.connect(_on_mission_success)
	MissionManager.penalty_incurred.connect(_on_penalty_incurred)
	
	status_label.text = "Find Start Zone"
	timer_label.text = "00:00"
	arrow_icon.visible = false 
	
	if penalty_label:
		penalty_label.modulate.a = 0.0
	
	player_ref = get_tree().current_scene.find_child("Player", true, false)

func _process(delta: float) -> void:
	if MissionManager.is_mission_active and player_ref and arrow_icon.visible:
		update_compass(delta)

func update_compass(delta: float) -> void:
	var cam = get_viewport().get_camera_3d()
	if not cam: return
	
	arrow_icon.pivot_offset = arrow_icon.size / 2
	var target_pos_3d = MissionManager.current_objective_pos
	var target_screen_pos = Vector2.ZERO
	
	# --- NEW BEHIND LOGIC ---
	# We convert the target to the Camera's local space to easily check Z (Depth)
	var local_target = cam.to_local(target_pos_3d)
	
	if local_target.z > 0:
		# BEHIND THE CAMERA (Z > 0 means behind in Godot's -Z forward system? 
		# actually unproject handles the -Z convention, but for manual logic:
		# Local Z > 0 is usually 'behind' if using standard -Z forward. 
		# Let's rely on is_position_behind to be 100% sure, then use local x for side.
		
		var screen_rect = get_viewport().get_visible_rect().size
		var center = screen_rect / 2
		
		# Force the position to be WAY off-screen at the bottom (Y+)
		# We use local_target.x to decide if it's Left or Right behind us.
		# We multiply by a large number to ensure the angle is sharp.
		var direction_factor = 1000.0
		target_screen_pos = center + Vector2(sign(local_target.x) * direction_factor, direction_factor)
		
	else:
		# IN FRONT
		target_screen_pos = cam.unproject_position(target_pos_3d)
	
	# Calculate Angle
	var arrow_center = arrow_icon.global_position + (arrow_icon.size / 2)
	var dir_vector = (target_screen_pos - arrow_center).normalized()
	
	var target_angle = dir_vector.angle() + deg_to_rad(icon_rotation_offset)
	
	# Apply Smoothing
	arrow_icon.rotation = lerp_angle(arrow_icon.rotation, target_angle, rotation_speed * delta)

# ... (Rest of the script remains unchanged)
func _on_time_updated(time: float) -> void:
	var display_time = max(0.0, time)
	var seconds = int(display_time)
	var mills = int((display_time - seconds) * 100)
	timer_label.text = "%02d:%02d" % [seconds, mills]
	
	if not is_flashing:
		if time < 10.0:
			timer_label.self_modulate = Color(1, 0, 0) 
		else:
			timer_label.self_modulate = Color(1, 1, 1) 

func _on_penalty_incurred(amount: float) -> void:
	is_flashing = true
	if flash_tween: flash_tween.kill()
	
	flash_tween = create_tween()
	flash_tween.tween_property(timer_label, "self_modulate", Color(1, 0, 0), 0.1)
	flash_tween.parallel().tween_property(timer_label, "scale", Vector2(1.2, 1.2), 0.1)
	flash_tween.tween_property(timer_label, "self_modulate", Color(1, 1, 1), 0.2)
	flash_tween.parallel().tween_property(timer_label, "scale", Vector2(1.0, 1.0), 0.2)
	flash_tween.tween_callback(func(): is_flashing = false)
	
	if penalty_label:
		penalty_label.text = "-%.1fs" % amount
		if penalty_tween: penalty_tween.kill()
		penalty_tween = create_tween()
		penalty_label.modulate.a = 0.0
		penalty_tween.tween_property(penalty_label, "modulate:a", 1.0, 0.1)
		penalty_tween.tween_interval(1.5)
		penalty_tween.tween_property(penalty_label, "modulate:a", 0.0, 1.0)

func _on_mission_started() -> void:
	status_label.text = "DELIVER!"
	status_label.modulate = Color.WHITE
	arrow_icon.visible = true 

func _on_mission_failed(reason: String) -> void:
	status_label.text = "FAILED: " + reason
	status_label.modulate = Color.RED
	arrow_icon.visible = false

func _on_mission_success() -> void:
	status_label.text = "COMPLETE"
	status_label.modulate = Color.GREEN
	arrow_icon.visible = false
