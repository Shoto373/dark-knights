class_name StateMachine
extends Node

## Конечный автомат состояний (State Machine)

signal state_changed(from_state: String, to_state: String)

@export var initial_state: String = "idle"

var current_state: State = null
var current_state_name: String = ""
var states: Dictionary = {} # String -> State

func _ready() -> void:
	var actor: CharacterBody2D = get_parent() as CharacterBody2D
	
	for child in get_children():
		if child is State:
			var state_name: String = child.name.to_lower()
			states[state_name] = child
			child.state_machine = self
			child.actor = actor
	
	if states.has(initial_state.to_lower()):
		change_state(initial_state.to_lower())

func _process(delta: float) -> void:
	if current_state != null:
		current_state.update(delta)

func _physics_process(delta: float) -> void:
	if current_state != null:
		current_state.physics_update(delta)

func change_state(new_state_name: String) -> void:
	new_state_name = new_state_name.to_lower()
	if not states.has(new_state_name):
		push_warning("StateMachine: state '%s' not found" % new_state_name)
		return
	
	if current_state_name == new_state_name:
		return
	
	var old_state_name: String = current_state_name
	if current_state != null:
		current_state.exit()
	
	current_state = states[new_state_name]
	current_state_name = new_state_name
	current_state.enter()
	
	state_changed.emit(old_state_name, new_state_name)
