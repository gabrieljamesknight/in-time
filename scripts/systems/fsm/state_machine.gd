class_name StateMachine
extends Node

@export var initial_state: Node

var current_state: State
var states: Dictionary = {}

func init(player: CharacterBody3D) -> void:
	for child in get_children():
		if child is State:
			# Register states by their node name (e.g., "Idle", "Run")
			states[child.name.to_lower()] = child
			child.player = player
	
	if initial_state:
		change_state(initial_state.name.to_lower())

func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

func change_state(new_state_name: String) -> void:
	var new_state = states.get(new_state_name.to_lower())
	if not new_state:
		return
	
	if current_state:
		current_state.exit()
	
	current_state = new_state
	print("Changed State to: " + current_state.name)
	current_state.enter()
