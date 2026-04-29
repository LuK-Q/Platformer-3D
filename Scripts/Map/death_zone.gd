extends Area3D

func _on_body_entered(body):
	if body.is_in_group("Player"):
		ScreenFader.reload_scene(0.8)
