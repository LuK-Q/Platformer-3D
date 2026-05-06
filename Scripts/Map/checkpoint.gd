extends Area3D

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("Player"):
		var current_scene = get_tree().current_scene.scene_file_path
		var cam = get_viewport().get_camera_3d()
		var cam_offset = Vector3.ZERO
		
		if cam and "target_offset" in cam:
			cam_offset = cam.target_offset
		
		GameManager.save_checkpoint(current_scene, global_position, cam_offset)
