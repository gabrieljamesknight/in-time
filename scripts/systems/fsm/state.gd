class_name State
extends Node

# Reference to the player (context)
var player: CharacterBody3D

# Virtual methods to be overridden
func enter() -> void:
	pass

func exit() -> void:
	pass

func update(_delta: float) -> void:
	pass

func physics_update(_delta: float) -> void:
	pass
