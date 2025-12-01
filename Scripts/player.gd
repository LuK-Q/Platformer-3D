extends CharacterBody3D

@export var speed = 14
@export var fall_acceleration = 50
@export var jump_impulse = 20
@export var bounce_impulse = 16
@export var turn_speed = 10.0
@export var move_smoothing = 8.0
@onready var camera: Camera3D = get_viewport().get_camera_3d()
var movement_direction := Vector3.ZERO
var target_velocity = Vector3.ZERO

func _physics_process(delta):

	# --- MOVEMENT INPUT (WASD + LEFT STICK) ---
	var input_dir_2d = Input.get_vector(
	"move_left", "move_right",
	"move_forward", "move_back"
	)	

	# Convert 2D input into 3D movement
	var input_dir = Vector3(input_dir_2d.x, 0, input_dir_2d.y)
	# Smooth acceleration (kills keyboard snapping)
	movement_direction = movement_direction.lerp(input_dir, delta * move_smoothing)
	# Kill tiny drifting input
	if input_dir.length() < 0.15:
		movement_direction = Vector3.ZERO

	if movement_direction.length() > 0.1:
		movement_direction = movement_direction.normalized()


	# --- TURNING INPUT (RIGHT STICK) ---
	var look_input = Vector2(
		Input.get_action_strength("look_right") - Input.get_action_strength("look_left"),
		-(Input.get_action_strength("look_up") - Input.get_action_strength("look_down"))
	)

	# CONTROLLER TURNING
	if look_input.length() > 0.2:
		var target_angle = atan2(-look_input.x, -look_input.y)
		$Pivot.rotation.y = lerp_angle(
		$Pivot.rotation.y,
		target_angle,
		delta * turn_speed * look_input.length()
	)

	# MOUSE TURNING (only if stick NOT used)

	else:
		var mouse_pos = get_viewport().get_mouse_position()
		var from = camera.project_ray_origin(mouse_pos)
		var to = from + camera.project_ray_normal(mouse_pos) * 2000

		var space = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(from, to)
		var result = space.intersect_ray(query)

		if result:
			var look_point = result.position
			look_point.y = $Pivot.global_position.y

			var target_rotation = $Pivot.global_position.direction_to(look_point)
			var target_angle = atan2(-target_rotation.x, -target_rotation.z)

			$Pivot.rotation.y = lerp_angle($Pivot.rotation.y, target_angle, delta * turn_speed)


	# --- ANIMATION CONTROL ---
	if movement_direction.length() > 0.1:
		$AnimationPlayer.speed_scale = 3.64
	else:
		$AnimationPlayer.speed_scale = 0

	# Ground Velocity
	#target_velocity.x = direction.x * speed
	#target_velocity.z = direction.z * speed
	target_velocity.x = movement_direction.x * speed
	target_velocity.z = movement_direction.z * speed

	# Vertical Velocity
	if not is_on_floor(): # If in the air, fall towards the floor
		target_velocity.y = target_velocity.y - (fall_acceleration * delta)
		$AnimationPlayer.speed_scale =3.64
	else:
		$AnimationPlayer.speed_scale = 0
	# Jumping.
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		target_velocity.y = jump_impulse

	# Moving the Character
	velocity = target_velocity
	move_and_slide()
