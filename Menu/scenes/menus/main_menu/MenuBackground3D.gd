extends Node3D

@onready var anim_tree = $playerModel/AnimationTree

@export var game_scene_path: String = "res://Scenes/main.tscn"
@export var ui_container: Control 
@export var play_button: Button 

@export var lamp: Node3D 
@export var dark_timer_seconds: float = 3.0
@export var ui_fade_duration: float = 2.0

func _ready():
	if play_button:
		var connections = play_button.get_signal_connection_list("pressed")
		for conn in connections:
			play_button.pressed.disconnect(conn.callable)
		play_button.pressed.connect(_on_play_button_pressed)

func _on_play_button_pressed():
	play_button.disabled = true
	anim_tree.set("parameters/conditions/start_game", true)
	
	if ui_container:
		var tween = create_tween()
		tween.tween_property(ui_container, "modulate:a", 0.0, ui_fade_duration)
		tween.finished.connect(func(): ui_container.hide())
		
	if lamp:
		#await get_tree().create_timer(dark_timer_seconds).timeout
		lamp.turn_off()

	#await get_tree().create_timer(dark_timer_seconds).timeout
	SceneLoader.load_scene(game_scene_path)
