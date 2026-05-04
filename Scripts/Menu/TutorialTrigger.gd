extends Area3D

@export var image_to_show: Texture2D
@export_multiline var text_to_show: String
@export var required_actions: Array[String] = [] 
@export var trigger_only_once: bool = true

var _used: bool = false

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("Player"):
		if trigger_only_once and _used:
			return

		TutorialSystem.show_tutorial(image_to_show, text_to_show, required_actions)
		_used = true
