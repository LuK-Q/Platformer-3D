class_name StateMachine
extends Node

@export var initial_state: State

var current_state: State
var states: Dictionary = {}

func _ready() -> void:
	# Czekamy aż gracz (CharacterBody3D) będzie w pełni gotowy
	await owner.ready
	var player = owner as CharacterBody3D
	
	# Automatycznie rejestrujemy wszystkie stany dodane jako dzieci tego węzła
	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			child.player = player
			child.state_machine = self
	
	if initial_state:
		initial_state.enter()
		current_state = initial_state

func _input(event: InputEvent) -> void:
	if current_state:
		current_state.handle_input(event)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)
	
# Funkcja wywoływana przez stany, by przejść do innego stanu
# StateMachine.gd
var previous_state: State # Nowa zmienna do walidacji parkouru

func transition_to(state_name: String) -> void:
	var key = state_name.to_lower()
	if not states.has(key) or current_state == states[key]:
		return
		
	if current_state:
		previous_state = current_state # Zapamiętujemy skąd przychodzimy
		current_state.exit()
		
	current_state = states[key]
	current_state.enter()
	# print("Zmiana stanu: ", previous_state.name if previous_state else "None", " -> ", current_state.name)
