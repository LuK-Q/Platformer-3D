extends Camera3D

@export var target: Node3D
@export var offset: Vector3 = Vector3(0, 3, 3)
@export var vertical_look_offset: float = 2.0
@export var follow_speed: float = 5
@export var rotation_speed: float = 5
@export var max_allowed_distance: float = 15.0

func _ready() -> void:
	if target != null:
		var look_target: Vector3 = target.global_position + Vector3.UP * vertical_look_offset
		look_at(look_target, Vector3.UP)

func _physics_process(delta: float) -> void:
	if target == null:
		return

	var desired_pos: Vector3 = target.global_position + offset
	
	var current_dist = global_position.distance_to(desired_pos)
	if current_dist > max_allowed_distance:
		var direction_to_desired = (global_position - desired_pos).normalized()
		global_position = desired_pos + (direction_to_desired * max_allowed_distance)

	global_position = global_position.lerp(desired_pos, follow_speed * delta)

	var look_target: Vector3 = target.global_position + Vector3.UP * vertical_look_offset
	var current_dir: Vector3 = -global_transform.basis.z.normalized()
	var desired_dir: Vector3 = (look_target - global_position).normalized()

	var new_dir: Vector3 = current_dir.slerp(desired_dir, rotation_speed * delta)
	look_at(global_position + new_dir, Vector3.UP)
