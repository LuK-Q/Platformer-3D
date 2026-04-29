extends Area3D

@export_file("*.tscn") var next_scene_path: String 
@export var transition_duration: float = 1.5

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("Player") and next_scene_path != "":
		set_deferred("monitoring", false)
		
		var tween = create_tween()
		tween.tween_property(ScreenFader.color_rect, "color:a", 1.0, transition_duration)
		await tween.finished
		
		get_tree().call_deferred("change_scene_to_file", next_scene_path)
		
		await get_tree().process_frame
		ScreenFader.fade_in(transition_duration)
