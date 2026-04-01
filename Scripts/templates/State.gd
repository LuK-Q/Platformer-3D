class_name State
extends Node

var player: CharacterBody3D
var state_machine: Node

# Wywoływane jednorazowo przy wejściu do stanu (tu będziemy odpalać animacje)
func enter() -> void:
	pass

# Wywoływane jednorazowo przy opuszczaniu stanu
func exit() -> void:
	pass

# Zastępuje główną pętlę _physics_process dla danego stanu
func physics_update(_delta: float) -> void:
	pass

# Do opcjonalnego przechwytywania wciśnięć klawiszy (np. skok)
func handle_input(_event: InputEvent) -> void:
	pass
