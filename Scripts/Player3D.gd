extends CharacterBody3D

@export var speed := 14.0
@export var fall_acceleration := 50.0
@export var jump_impulse := 20.0
@export var turn_speed := 10.0
@export var move_smoothing := 8.0
@export var deadzone := 0.15

@onready var camera: Camera3D = get_viewport().get_camera_3d()
@onready var pivot: Node3D = $Pivot
@onready var anim: AnimationPlayer = $AnimationPlayer

var movement_direction := Vector3.ZERO
var target_velocity := Vector3.ZERO

func _physics_process(delta: float) -> void:

	# -------- MOVEMENT INPUT --------
	var input_2d := Input.get_vector("move_left", "move_right", "move_forward", "move_back")

	if input_2d.length() > deadzone:
		var desired_dir := Vector3(input_2d.x, 0, input_2d.y).normalized()
		movement_direction = movement_direction.lerp(desired_dir, delta * move_smoothing)
	else:
		movement_direction = movement_direction.lerp(Vector3.ZERO, delta * move_smoothing)

	target_velocity.x = movement_direction.x * speed
	target_velocity.z = movement_direction.z * speed


	# -------- TURN INPUT  --------
	var look_input := Vector2(
		Input.get_action_strength("look_right") - Input.get_action_strength("look_left"),
		Input.get_action_strength("look_down") - Input.get_action_strength("look_up")
	)

	var target_angle: float
	var has_target := false

	# Right stick handling
	if look_input.length() > 0.2:
		target_angle = atan2(-look_input.x, -look_input.y)
		has_target = true

	# Mouse handling
	else:
		var mouse_pos := get_viewport().get_mouse_position()
		var from := camera.project_ray_origin(mouse_pos)
		var to := from + camera.project_ray_normal(mouse_pos) * 2000

		var query := PhysicsRayQueryParameters3D.create(from, to)
		var result := get_world_3d().direct_space_state.intersect_ray(query)

		if result:
			var flat_target: Vector3 = result.position
			flat_target.y = pivot.global_position.y
			var dir := pivot.global_position.direction_to(flat_target)
			target_angle = atan2(-dir.x, -dir.z)
			has_target = true

	# Smooth rotation
	if has_target:
		pivot.rotation.y = lerp_angle(pivot.rotation.y,target_angle,delta * turn_speed)


	# -------- GRAVITY + JUMP --------
	if not is_on_floor():
		target_velocity.y -= fall_acceleration * delta
		anim.speed_scale = 3.64
	else:
		target_velocity.y = 0
		anim.speed_scale = 0

	if is_on_floor() and Input.is_action_just_pressed("jump"):
		target_velocity.y = jump_impulse


	velocity = target_velocity
	move_and_slide()
