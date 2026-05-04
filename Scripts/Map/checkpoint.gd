extends Area3D

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("Player"):
		var current_scene = get_tree().current_scene.scene_file_path
		GameManager.save_checkpoint(current_scene, global_position)
		# Opcjonalnie:  efekt wizualny 
