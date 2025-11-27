extends CanvasLayer

@onready var timer_label: Label = $Control/TimerLabel
@onready var status_label: Label = $Control/StatusLabel

# 320x240 Res: Top Right corner target
var corner_pos: Vector2 = Vector2(230, 10) 

# STATE VARIABLES
var is_flashing: bool = false
var flash_tween: Tween # [NEW] We store the tween here to control it

func _ready() -> void:
	# Connect signals
	MissionManager.time_updated.connect(_on_time_updated)
	MissionManager.mission_started.connect(_on_mission_started)
	MissionManager.mission_failed.connect(_on_mission_failed)
	MissionManager.mission_success.connect(_on_mission_success)
	MissionManager.penalty_incurred.connect(_on_penalty_incurred)
	
	status_label.text = "Find Start Zone"
	status_label.modulate.a = 1.0
	
	timer_label.text = "00:00"
	# Reset color to pure white
	timer_label.self_modulate = Color(1, 1, 1)
	
	# Force pivot to center so it scales from the middle, not top-left
	# We wait one frame to ensure the label has calculated its size
	await get_tree().process_frame
	timer_label.pivot_offset = timer_label.size / 2

func _on_time_updated(time: float) -> void:
	var display_time = max(0.0, time)
	var seconds = int(display_time)
	var mills = int((display_time - seconds) * 100)
	timer_label.text = "%02d:%02d" % [seconds, mills]
	
	# Only update colors if the Penalty Animation is NOT running
	if not is_flashing:
		if time < 10.0:
			timer_label.self_modulate = Color(1, 0, 0) # Low Time Red
		else:
			timer_label.self_modulate = Color(1, 1, 1) # Normal White

func _on_penalty_incurred(_amount: float) -> void:
	print("HUD: Starting Flash Animation")
	
	# 1. LOCK the update loop
	is_flashing = true
	
	# 2. KILL any existing animation so they don't fight
	if flash_tween:
		flash_tween.kill()
	
	# 3. CREATE a new fresh tween
	flash_tween = create_tween()
	
	# STEP A: Pop to Red and Scale Up (0.1 seconds)
	flash_tween.tween_property(timer_label, "self_modulate", Color(1, 0, 0), 0.1).set_trans(Tween.TRANS_CUBIC)
	flash_tween.parallel().tween_property(timer_label, "scale", Vector2(0.6, 0.6), 0.1).set_trans(Tween.TRANS_BOUNCE)
	
	# STEP B: Return to White and Scale Down (0.2 seconds)
	flash_tween.tween_property(timer_label, "self_modulate", Color(1, 1, 1), 0.2)
	flash_tween.parallel().tween_property(timer_label, "scale", Vector2(0.4, 0.4), 0.2)
	
	# 4. UNLOCK when finished
	flash_tween.tween_callback(func(): is_flashing = false)

func _on_mission_started() -> void:
	status_label.text = "DELIVER!"
	
	var tween = create_tween()
	
	# Fade out status text
	tween.tween_interval(1.5)
	tween.tween_property(status_label, "modulate:a", 0.0, 1.0)
	
	# Move timer to corner
	var timer_tween = create_tween()
	timer_tween.set_parallel(true)
	timer_tween.set_trans(Tween.TRANS_CUBIC)
	timer_tween.set_ease(Tween.EASE_OUT)
	
	timer_tween.tween_property(timer_label, "scale", Vector2(0.4, 0.4), 1.0)
	timer_tween.tween_property(timer_label, "position", corner_pos, 1.0)

func _on_mission_failed(reason: String) -> void:
	_reset_ui("FAILED\n" + reason, Color.RED)

func _on_mission_success() -> void:
	_reset_ui("COMPLETE", Color.GREEN)

func _reset_ui(text: String, color: Color) -> void:
	# Kill flash tween if it's running so it doesn't stuck on red
	if flash_tween: flash_tween.kill()
	is_flashing = false
	
	status_label.text = text
	status_label.modulate = color
