extends Node

# Signals
signal time_updated(current_time: float)
signal mission_started
signal mission_success
signal mission_failed(reason: String)
# [NEW] Signal for global game events
signal crime_committed(thief: Node3D)

# Config
var max_mission_time: float = 60.0 
var time_penalty_hit: float = 5.0  
var time_penalty_wipe: float = 10.0 
var time_penalty_mugged: float = 15.0 
var time_penalty_hard_land: float = 3.0 
# [NEW] Instant fail or massive penalty for theft in plain sight
var time_penalty_caught_stealing: float = 30.0 

# State
var current_time: float = 0.0
var is_mission_active: bool = false

func _process(delta: float) -> void:
	if is_mission_active:
		current_time -= delta
		emit_signal("time_updated", current_time)
		
		if current_time <= 0:
			fail_mission("Time Expired")

func start_mission(duration: float) -> void:
	print("Mission Started! Go!")
	current_time = duration
	is_mission_active = true
	emit_signal("mission_started")

func complete_mission() -> void:
	if not is_mission_active: return
	
	is_mission_active = false
	print("Mission Complete! Time left: ", snapped(current_time, 0.01))
	emit_signal("mission_success")

func fail_mission(reason: String) -> void:
	if not is_mission_active: return
	is_mission_active = false
	print("Mission Failed: " + reason)
	emit_signal("mission_failed", reason)
	
	# Reload scene after delay
	await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()

func apply_penalty(amount: float) -> void:
	if is_mission_active:
		current_time -= amount
		print("PENALTY APPLIED: -", amount, "s")
		
# [NEW] Helper to report crime
func report_theft(thief: Node3D) -> void:
	emit_signal("crime_committed", thief)
