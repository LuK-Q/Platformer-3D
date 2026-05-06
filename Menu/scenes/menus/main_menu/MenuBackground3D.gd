extends Node3D

@onready var anim_tree = $playerModel/AnimationTree
@onready var camera = $Camera3D

@export var game_scene_path: String = "res://Scenes/main.tscn"
@export var ui_container: Control 
@export var play_button: Button 

@export var lamp: Node3D 
@export var dark_timer_seconds: float = 3.0
@export var ui_fade_duration: float = 2.0

@export var shake_intensity: float = 0.015
@export var shake_speed: float = 25.0
var base_camera_pos: Vector3
var shake_time: float = 0.0
# -------------------------------

func _ready():
	if camera:
		base_camera_pos = camera.position

	if play_button:
		var connections = play_button.get_signal_connection_list("pressed")
		for conn in connections:
			play_button.pressed.disconnect(conn.callable)
		play_button.pressed.connect(_on_play_button_pressed)

func _process(delta):
	if camera:
		shake_time += delta * shake_speed *0.2
		
		var offset_x = sin(shake_time) * cos(shake_time * 0.7) * shake_intensity
		var offset_y = sin(shake_time * 1.3) * cos(shake_time * 1.1) * (shake_intensity * 1.5)
		
		camera.position = base_camera_pos + Vector3(offset_x, offset_y, 0)

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
