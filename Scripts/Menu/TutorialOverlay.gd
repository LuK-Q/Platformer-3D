extends CanvasLayer

@onready var control = $Control
@onready var texture_rect = $Control/TutorialImage
@onready var label = $Control/Label

var is_active: bool = false
var can_close: bool = false
var target_actions: Array = [] 

func _ready():
	control.hide()
	get_tree().paused = false

func show_tutorial(image: Texture2D, text: String = "", actions: Array = []):
	if is_active: return

	texture_rect.texture = image
	target_actions = actions
	
	if text != "":
		label.text = text
		label.show()
	else:
		label.hide()
	
	control.show()
	is_active = true
	can_close = false
	get_tree().paused = true
	
	await get_tree().create_timer(1.0).timeout
	can_close = true

func _input(event):
	if not (is_active and can_close):
		return

	if event is InputEventMouseMotion or not event.is_pressed():
		return

	if target_actions.is_empty():
		if event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton:
			_close_tutorial()
			get_viewport().set_input_as_handled()
	else:
		for action in target_actions:
			if event.is_action_pressed(action):
				_close_tutorial()
				get_viewport().set_input_as_handled()
				break

func _close_tutorial():
	control.hide()
	is_active = false
	can_close = false
	target_actions = []
	get_tree().paused = false
