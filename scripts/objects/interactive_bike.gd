class_name InteractiveBike
extends StaticBody3D

# Called by the InteractionZone signals
func _on_interaction_zone_body_entered(body: Node3D) -> void:
	# Check if the body is the Player
	if body.name == "Player":
		body.current_interactable = self
		print("Bike in range")

func _on_interaction_zone_body_exited(body: Node3D) -> void:
	if body.name == "Player":
		# Only clear if WE are the object currently referenced
		if body.current_interactable == self:
			body.current_interactable = null
			print("Bike out of range")

# Called by the Player FSM when 'E' is pressed
func interact() -> void:
	print("Bike Acquired! Destroying world object...")
	
	# FIND THE PLAYER (The thief is the one currently interacting with us)
	# Since we are in the 'interact' function, we know the player is close.
	# We can cheat and grab the player from the "InteractionZone" overlap if needed,
	# but it's cleaner to just get the tree's player or pass it.
	
	# QUICK FIX: Assume the body inside the zone is the thief.
	var bodies = $InteractionZone.get_overlapping_bodies()
	for body in bodies:
		if body.name == "Player":
			MissionManager.report_theft(body)
			break
	
	queue_free()
