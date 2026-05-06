extends Camera3D

@export var target: Node3D
@export var offset: Vector3 = Vector3(50, 50, -50) 
@export var vertical_look_offset: float = 1.5
@export var follow_speed: float = 8
@export var rotation_speed: float = 5
@export var max_allowed_distance: float = 15.0

var target_offset :Vector3
var offset_rotation_speed: float = 6.0

@onready var occlusion_ray: RayCast3D = $RayCast3D
var last_occluder: GeometryInstance3D = null

func _ready() -> void:
	target_offset = offset
	if target != null:
		var look_target: Vector3 = target.global_position + Vector3.UP * vertical_look_offset
		look_at(look_target, Vector3.UP)
		
func _process(_delta: float) -> void:

	if Input.is_action_just_pressed("camera_rotate_left"):

		target_offset = target_offset.rotated(Vector3.UP, deg_to_rad(-90))
	elif Input.is_action_just_pressed("camera_rotate_right"):

		target_offset = target_offset.rotated(Vector3.UP, deg_to_rad(90))
		
func _physics_process(delta: float) -> void:
	if target == null:
		return
		
	offset = offset.lerp(target_offset, offset_rotation_speed * delta)
	var desired_pos: Vector3 = target.global_position + offset
	var current_dist = global_position.distance_to(desired_pos)
	
	if current_dist > max_allowed_distance:
		var direction_to_desired = (global_position - desired_pos).normalized()
		global_position = desired_pos + (direction_to_desired * max_allowed_distance)

	global_position = global_position.lerp(desired_pos, follow_speed * delta)
	_instant_look_at()
	_handle_occlusion(delta)
	
	#var look_target: Vector3 = target.global_position + Vector3.UP * vertical_look_offset
	#var current_dir: Vector3 = -global_transform.basis.z.normalized()
	#var desired_dir: Vector3 = (look_target - global_position).normalized()

	#var new_dir: Vector3 = current_dir.slerp(desired_dir, rotation_speed * delta)
	#look_at(global_position + new_dir, Vector3.UP)

func _instant_look_at() -> void:
	var look_target: Vector3 = target.global_position + Vector3.UP * vertical_look_offset
	look_at(look_target, Vector3.UP)
func _handle_occlusion(delta: float) -> void:
	var look_target: Vector3 = target.global_position + Vector3.UP * vertical_look_offset
	occlusion_ray.target_position = occlusion_ray.to_local(look_target)
	occlusion_ray.force_raycast_update()
	
	var current_hit = occlusion_ray.get_collider() as GeometryInstance3D
	
	if current_hit != last_occluder:
		if last_occluder != null:
			_fade_object(last_occluder, 0.0) 
		
		last_occluder = current_hit
		
	if last_occluder != null:
		last_occluder.transparency = lerp(last_occluder.transparency, 0.85, 10.0 * delta)

func _fade_object(obj: GeometryInstance3D, target_alpha: float) -> void:
	if obj == null: return
	var tween = get_tree().create_tween()
	tween.tween_property(obj, "transparency", target_alpha, 0.3)
	
func force_set_offset(new_offset: Vector3) -> void:
	target_offset = new_offset
	offset = new_offset
	if target:
		var look_target: Vector3 = target.global_position + Vector3.UP * vertical_look_offset
		global_position = look_target + new_offset
		look_at(look_target, Vector3.UP)
