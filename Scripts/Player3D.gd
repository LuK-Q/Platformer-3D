extends CharacterBody3D

@export var max_speed := 14.0
@export var acceleration := 38.0
@export var deceleration := 30.0
@export var air_acceleration := 12.0
@export var turn_speed := 12.0

@export var gravity := 50.0
@export var jump_impulse := 20.0

@export var deadzone := 0.15

@onready var camera: Camera3D = get_viewport().get_camera_3d()
@onready var pivot: Node3D = $Pivot
@onready var anim_tree: AnimationTree = $Pivot/playerModel/AnimationTree

var movement_direction := Vector3.ZERO
var target_velocity := Vector3.ZERO

func _ready():
	anim_tree.active = true

func _physics_process(delta: float) -> void:
	# -------- INPUT --------
	var input_2d := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if input_2d.length() < deadzone:
		input_2d = Vector2.ZERO

	# -------- CAMERA-RELATIVE DIRECTION --------
	var cam_basis := camera.global_transform.basis
	var cam_forward := -cam_basis.z
	var cam_right := cam_basis.x

	cam_forward.y = 0
	cam_right.y = 0
	cam_forward = cam_forward.normalized()
	cam_right = cam_right.normalized()

	var desired_dir := (cam_right * input_2d.x + cam_forward * -input_2d.y)
	if desired_dir.length() > 0:
		desired_dir = desired_dir.normalized()

	# -------- ACCELERATION / MOMENTUM --------
	var current_accel := acceleration if is_on_floor() else air_acceleration
	var current_decel := deceleration
	var desired_velocity := desired_dir * max_speed

	target_velocity.x = move_toward(target_velocity.x, desired_velocity.x, current_accel * delta)
	target_velocity.z = move_toward(target_velocity.z, desired_velocity.z, current_accel * delta)

	# Deceleration when no input
	if desired_dir == Vector3.ZERO:
		target_velocity.x = move_toward(target_velocity.x, 0.0, current_decel * delta)
		target_velocity.z = move_toward(target_velocity.z, 0.0, current_decel * delta)

	# -------- CLAMP HORIZONTAL SPEED --------
	var horizontal := Vector2(target_velocity.x, target_velocity.z)
	horizontal = horizontal.limit_length(max_speed)
	target_velocity.x = horizontal.x
	target_velocity.z = horizontal.y

	# -------- GRAVITY & JUMP --------
	if is_on_floor():
		if target_velocity.y < 0:
			target_velocity.y = 0
		if Input.is_action_just_pressed("jump"):
			target_velocity.y = jump_impulse
	else:
		target_velocity.y -= gravity * delta

	# -------- APPLY MOVEMENT --------
	velocity = target_velocity
	move_and_slide()

	# -------- FACING (MOVEMENT-DRIVEN) --------
	if horizontal.length() > 0.1:
		var facing_angle := atan2(-horizontal.x, -horizontal.y)
		pivot.rotation.y = lerp_angle(pivot.rotation.y, facing_angle, delta * turn_speed)

	update_animation()


func update_animation():
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	var blend_speed: float = clamp(horizontal_speed / max_speed, 0.0, 1.0)

	anim_tree.set("parameters/Locomotion/blend_position", Vector2(0.0, blend_speed))
