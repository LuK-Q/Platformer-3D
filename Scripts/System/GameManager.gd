extends Node

var last_checkpoint_scene: String = ""
var last_checkpoint_position: Vector3 = Vector3.ZERO
var has_checkpoint: bool = false

func save_checkpoint(scene_path: String, position: Vector3):
	last_checkpoint_scene = scene_path
	last_checkpoint_position = position
	has_checkpoint = true

func clear_checkpoint():
	has_checkpoint = false
