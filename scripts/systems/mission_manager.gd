extends Node

# Signals for the HUD and other systems to listen to
signal time_updated(current_time: float)
signal mission_started
signal mission_success
signal mission_failed(reason: String)

# Config
var max_mission_time: float = 60.0 # Default, changes per mission
var time_penalty_hit: float = 5.0  # Seconds lost when hit by car
var time_penalty_wipe: float = 10.0 # Seconds lost when bike crashes

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
	# TODO: Add Score Calculation here later

func fail_mission(reason: String) -> void:
	is_mission_active = false
	print("Mission Failed: " + reason)
	emit_signal("mission_failed", reason)
	# For now, just reload the scene after a delay so we can try again
	await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()

func apply_penalty(amount: float) -> void:
	if is_mission_active:
		current_time -= amount
		print("PENALTY APPLIED: -", amount, "s")
		# Flash the screen red here in future
