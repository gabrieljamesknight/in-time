extends Node

# --- SIGNALS ---
signal time_updated(current_time: float)
signal mission_started
signal mission_success
signal mission_failed(reason: String)
signal crime_committed(thief: Node3D)
signal penalty_incurred(amount: float)

# --- CONFIG ---
var max_mission_time: float = 60.0 
var time_penalty_hit: float = 5.0  
var time_penalty_wipe: float = 10.0 
var time_penalty_mugged: float = 15.0 
var time_penalty_hard_land: float = 3.0 
var time_penalty_caught_stealing: float = 30.0 

# --- STATE ---
var current_time: float = 0.0
var is_mission_active: bool = false
var current_objective_pos: Vector3 = Vector3.ZERO # [NEW] target location

func _process(delta: float) -> void:
	if is_mission_active:
		current_time -= delta
		emit_signal("time_updated", current_time)
		
		if current_time <= 0:
			fail_mission("Time Expired")

func start_mission(duration: float, target_pos: Vector3) -> void:
	print("MissionManager: Received Start Command. Target: ", target_pos)
	current_time = duration
	current_objective_pos = target_pos # <--- This variable must be updated!
	is_mission_active = true
	emit_signal("mission_started")

func complete_mission() -> void:
	if not is_mission_active: return
	is_mission_active = false
	print("Mission Complete!")
	emit_signal("mission_success")

func fail_mission(reason: String) -> void:
	if not is_mission_active: return
	is_mission_active = false
	print("Mission Failed: " + reason)
	emit_signal("mission_failed", reason)
	
	await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()

func apply_penalty(amount: float) -> void:
	if is_mission_active:
		current_time -= amount
		emit_signal("penalty_incurred", amount)
		print("PENALTY APPLIED: -", amount, "s")

func report_theft(thief: Node3D) -> void:
	emit_signal("crime_committed", thief)
