class_name StateMachine
extends Node
## Generic finite state machine
## Manages state transitions and delegates update calls to active state
## Usage: Add State nodes as children, call transition_to() to change states

signal state_changed(from_state: String, to_state: String)

@export var initial_state: NodePath

var current_state: State = null
var states: Dictionary = {}


func _ready() -> void:
	# Wait for owner to be ready
	await owner.ready

	# Register all child State nodes
	for child in get_children():
		if child is State:
			states[child.name] = child
			child.state_machine = self
			child.finished.connect(_on_state_finished)

	# Initialize to first state
	if initial_state:
		var state = get_node(initial_state)
		if state is State:
			current_state = state
			current_state.enter()


func _physics_process(delta: float) -> void:
	if current_state:
		current_state.update(delta)


func transition_to(state_name: String, data: Dictionary = {}) -> void:
	if not states.has(state_name):
		push_warning("State '%s' does not exist" % state_name)
		return

	if current_state == states[state_name]:
		return

	var previous_state_name = ""
	if current_state:
		previous_state_name = current_state.name
		current_state.exit()

	current_state = states[state_name]
	current_state.enter(data)

	state_changed.emit(previous_state_name, state_name)


func get_current_state_name() -> String:
	return current_state.name if current_state else ""


func _on_state_finished(next_state: String, data: Dictionary) -> void:
	transition_to(next_state, data)
