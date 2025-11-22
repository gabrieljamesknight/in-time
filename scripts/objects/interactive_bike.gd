class_name InteractiveBike
extends StaticBody3D

# Called by the InteractionZone signals
func _on_interaction_zone_body_entered(body: Node3D) -> void:
	# Check if the body is the Player (referencing your player class logic)
	if body.name == "Player":
		# We assume you added 'current_interactable' to player_controller.gd
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
	# In the future: Play a sound effect here
	queue_free()
