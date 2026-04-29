extends CanvasLayer

var color_rect: ColorRect

func _ready():
	layer = 100 
	
	color_rect = ColorRect.new()
	color_rect.color = Color(0, 0, 0, 0) 
	color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE 
	add_child(color_rect)

func reload_scene(duration: float = 0.5):

	var tween = create_tween()
	tween.tween_property(color_rect, "color:a", 1.0, duration)
	await tween.finished
	
	get_tree().call_deferred("reload_current_scene")

	await get_tree().process_frame
	
	fade_in(duration)

func fade_in(duration: float = 0.5):
	var tween = create_tween()
	tween.tween_property(color_rect, "color:a", 0.0, duration)
