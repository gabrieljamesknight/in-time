extends CanvasLayer

# Updated path to include the new VBoxContainer
@onready var timer_label: Label = $Control/TimerContainer/VBoxContainer/TimerLabel
@onready var penalty_label: Label = $Control/TimerContainer/VBoxContainer/PenaltyLabel
@onready var status_label: Label = $Control/StatusContainer/StatusLabel
@onready var arrow_icon: Control = $Control/ArrowControl/ArrowIcon 

@export var icon_rotation_offset: float = 90.0

# STATE VARIABLES
var is_flashing: bool = false
var flash_tween: Tween 
var penalty_tween: Tween # New tween specifically for the text fade
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
	
	# Ensure penalty label is invisible on start
	if penalty_label:
		penalty_label.modulate.a = 0.0
	
	player_ref = get_tree().current_scene.get_node_or_null("Player")

	await get_tree().process_frame
	# Automatically set the pivot to the exact center of the icon
	if arrow_icon:
		arrow_icon.pivot_offset = arrow_icon.size / 2

func _process(_delta: float) -> void:
	if MissionManager.is_mission_active and player_ref and arrow_icon.visible:
		update_compass()

func update_compass() -> void:
	var cam = get_viewport().get_camera_3d()
	if not cam: return
	
	# 1. Get flat 2D positions (Ignore Y height)
	var player_flat = Vector2(cam.global_position.x, cam.global_position.z)
	var target_flat = Vector2(MissionManager.current_objective_pos.x, MissionManager.current_objective_pos.z)
	
	# 2. Calculate the direction to target in global space
	var dir_to_target = (target_flat - player_flat).normalized()
	
	# 3. Get Camera's "Flat" Forward direction
	var cam_fwd_3d = -cam.global_transform.basis.z
	var cam_fwd_flat = Vector2(cam_fwd_3d.x, cam_fwd_3d.z).normalized()
	
	# 4. Calculate Angle between Camera Look and Target
	var angle = cam_fwd_flat.angle_to(dir_to_target)
	
	# 5. Apply to Icon (Convert Offset to Radians)
	arrow_icon.rotation = angle + deg_to_rad(icon_rotation_offset)

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
	# --- 1. Flash the Timer (Existing Logic) ---
	is_flashing = true
	if flash_tween: flash_tween.kill()
	
	flash_tween = create_tween()
	flash_tween.tween_property(timer_label, "self_modulate", Color(1, 0, 0), 0.1)
	flash_tween.parallel().tween_property(timer_label, "scale", Vector2(1.2, 1.2), 0.1)
	flash_tween.tween_property(timer_label, "self_modulate", Color(1, 1, 1), 0.2)
	flash_tween.parallel().tween_property(timer_label, "scale", Vector2(1.0, 1.0), 0.2)
	flash_tween.tween_callback(func(): is_flashing = false)
	
	# --- 2. Show Penalty Text (New Logic) ---
	if penalty_label:
		# Format text (e.g., "-5.0s")
		penalty_label.text = "-%.1fs" % amount
		
		# Reset any running animation
		if penalty_tween: penalty_tween.kill()
		penalty_tween = create_tween()
		
		# Reset alpha to 0 just in case, then snap to 1
		penalty_label.modulate.a = 0.0
		
		# Animation: Fade In fast -> Wait -> Fade Out slow
		penalty_tween.tween_property(penalty_label, "modulate:a", 1.0, 0.1)
		penalty_tween.tween_interval(1.5) # Text stays visible for 1.5 seconds
		penalty_tween.tween_property(penalty_label, "modulate:a", 0.0, 1.0) # Fades out over 1 second

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
