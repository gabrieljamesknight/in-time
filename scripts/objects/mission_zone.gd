class_name MissionZone
extends Area3D

enum ZoneType { START, END }

@export var type: ZoneType = ZoneType.START
@export var mission_time: float = 45.0
@export var target_zone: Node3D # Drag EndZone here in Inspector

func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		if type == ZoneType.START:
			# Only start if not already running
			if not MissionManager.is_mission_active:
				var dest = Vector3.ZERO
				
				# --- DEBUG CHECK ---
				if target_zone:
					dest = target_zone.global_position
					print("StartZone: Found Target at ", dest)
				else:
					print("StartZone ERROR: 'Target Zone' is empty in the Inspector!")
				# -------------------
				
				MissionManager.start_mission(mission_time, dest)
				visible = false 
				
		elif type == ZoneType.END:
			# Only finish if running
			if MissionManager.is_mission_active:
				MissionManager.complete_mission()
