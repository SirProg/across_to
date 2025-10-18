class_name State
extends Node
## Base class for all states in a state machine
## Override enter(), exit(), and update() in child classes

signal finished(next_state: String, data: Dictionary)

var state_machine: StateMachine = null


## Called when entering this state
func enter(_data: Dictionary = {}) -> void:
	pass


## Called when exiting this state
func exit() -> void:
	pass


## Called every physics frame while in this state
func update(_delta: float) -> void:
	pass


## Call this to transition to another state
func finish(next_state: String = "", data: Dictionary = {}) -> void:
	finished.emit(next_state, data)
