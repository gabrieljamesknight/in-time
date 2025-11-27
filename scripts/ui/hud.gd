extends CanvasLayer

@onready var timer_label: Label = $Control/TimerLabel
@onready var status_label: Label = $Control/StatusLabel

func _ready() -> void:
	# Connect to the singleton signals
	MissionManager.time_updated.connect(_on_time_updated)
	MissionManager.mission_started.connect(_on_mission_started)
	MissionManager.mission_failed.connect(_on_mission_failed)
	MissionManager.mission_success.connect(_on_mission_success)
	
	status_label.text = "Find Start Zone"
	timer_label.text = "00:00"

func _on_time_updated(time: float) -> void:
	# Prevent negative numbers on UI
	var display_time = max(0.0, time)
	
	var seconds = int(display_time)
	var mills = int((display_time - seconds) * 100)
	timer_label.text = "%02d:%02d" % [seconds, mills]
	
	# Turn RED if under 10 seconds
	if time < 10.0:
		timer_label.modulate = Color(1, 0, 0)
	else:
		timer_label.modulate = Color(1, 1, 1)

func _on_mission_started() -> void:
	status_label.text = ""

func _on_mission_failed(reason: String) -> void:
	status_label.text = "FAILED\n" + reason
	status_label.modulate = Color.RED

func _on_mission_success() -> void:
	status_label.text = "DELIVERY COMPLETE"
	status_label.modulate = Color.GREEN
