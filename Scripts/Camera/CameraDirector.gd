extends Node
class_name CameraDirector

@export var camera: Camera3D
@export var default_target: Node3D
@export var default_offset: Vector3 = Vector3(50, 50, -50)

var _stack: Array = []
var _timer: SceneTreeTimer


func _ready() -> void:
	if camera == null:
		push_error("CameraDirector: No camera assigned.")
		return

	if default_target:
		camera.target = default_target
	camera.offset = default_offset


func focus_on(target: Node3D, offset: Vector3 = default_offset, duration: float = 1.5, follow_speed: float = 2.0, rotation_speed: float = 1.5) -> void:
	if camera == null or target == null:
		return
	_push_state()
	camera.target = target
	camera.offset = offset
	var old_follow_speed = camera.follow_speed
	var old_rotation_speed = camera.rotation_speed
	camera.follow_speed = follow_speed
	camera.rotation_speed = rotation_speed

	if duration > 0.0:
		if _timer:
			_timer = null
		_timer = get_tree().create_timer(duration)
		_timer.timeout.connect(func() -> void:
			camera.follow_speed = old_follow_speed
			camera.rotation_speed = old_rotation_speed
			_pop_state()
		, CONNECT_ONE_SHOT)

func reset_to_default() -> void:
	_stack.clear()
	if default_target:
		camera.target = default_target
	camera.offset = default_offset


func _push_state() -> void:
	var state := {
		"target": camera.target,
		"offset": camera.offset
	}
	_stack.push_back(state)


func _pop_state() -> void:
	if _stack.is_empty():
		reset_to_default()
		return

	var state: Dictionary = _stack.pop_back()
	camera.target = state["target"]
	camera.offset = state["offset"]
