extends CharacterBody3D

@export_group("Movement")
@export var base_speed := 4.0
@export var sprint_speed := 8.0
@export var acceleration := 30.0
@export var friction := 35.0
@export var air_control := 0.05

@export_group("Jump & Gravity")
@export var jump_velocity := 10.0
@export var gravity_multiplier := 3.5
@export var fall_gravity_multiplier := 5.0

@export_group("Momentum System")
@export var max_momentum_speed := 18.0
@export var momentum_gain_rate := 1.5

@export_group("Sliding & Crouching")
@export var slide_speed_multiplier := 1.2
@export var slide_friction := 15.0
@export var slide_timer_max := 0.8
@export var slide_activation_threshold := 8.0

# --- REFERENCJE ---
@onready var pivot: Node3D = $Pivot
@onready var camera_node: Camera3D = get_viewport().get_camera_3d()
@onready var ceiling_ray: RayCast3D = $CeilingRay

# Nowe kolizje zamiast jednej starej
@onready var lower_collision: CollisionShape3D = $LowerCollision
@onready var upper_collision: CollisionShape3D = $UpperCollision

# --- ZMIENNE STANU ---
var momentum := 0.0
var current_target_speed := 0.0
var is_sprinting := false
var is_sliding := false
var is_crouching := false
var slide_timer := 0.0

func _ready() -> void:
	# Sprawdzamy, czy węzły istnieją, żeby uniknąć błędów w konsoli
	if not lower_collision or not upper_collision:
		push_error("BŁĄD: Brakuje węzłów LowerCollision lub UpperCollision!")
	if not ceiling_ray:
		push_error("BŁĄD: Brakuje węzła CeilingRay!")

func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var cam_basis := camera_node.global_transform.basis
	var forward := Vector3(cam_basis.z.x, 0, cam_basis.z.z).normalized()
	var right := Vector3(cam_basis.x.x, 0, cam_basis.x.z).normalized()
	var direction := (forward * input_dir.y + right * input_dir.x).normalized()

	# 1. OBSŁUGA KUCANIA / ŚLIZGU
	var horizontal_speed = Vector2(velocity.x, velocity.z).length()

	if Input.is_action_just_pressed("crouch") and is_on_floor():
		if horizontal_speed > slide_activation_threshold:
			start_slide()
		else:
			start_crouch()

	if is_crouching and not Input.is_action_pressed("crouch") and not is_ceiling_above():
		stop_crouch()

	# 2. GRAWITACJA I SKOK
	if not is_on_floor():
		var grav = get_gravity_value() * (gravity_multiplier if velocity.y > 0 else fall_gravity_multiplier)
		velocity.y -= grav * delta
	else:
		if Input.is_action_just_pressed("jump"):
			if is_sliding or is_crouching:
				if not is_ceiling_above():
					velocity.y = jump_velocity * 0.8
					if is_sliding: stop_slide()
					else: stop_crouch()
			else:
				velocity.y = jump_velocity

	# 3. LOGIKA RUCHU
	if is_sliding:
		handle_slide(delta)
	elif is_on_floor():
		if is_crouching:
			handle_crouch_movement(delta, direction)
		else:
			handle_normal_movement(delta, direction)
	else:
		apply_air_movement(delta, direction)

	move_and_slide()

func start_slide() -> void:
	is_sliding = true
	is_crouching = false
	slide_timer = slide_timer_max
	set_slide_collision(true)
	velocity.x *= slide_speed_multiplier
	velocity.z *= slide_speed_multiplier

func handle_slide(delta: float) -> void:
	slide_timer -= delta
	velocity.x = move_toward(velocity.x, 0, slide_friction * delta)
	velocity.z = move_toward(velocity.z, 0, slide_friction * delta)

	if slide_timer <= 0:
		if Input.is_action_pressed("crouch") or is_ceiling_above():
			is_sliding = false
			is_crouching = true
		else:
			stop_slide()

func stop_slide() -> void:
	is_sliding = false
	is_crouching = false
	set_slide_collision(false)

func start_crouch() -> void:
	is_crouching = true
	set_slide_collision(true)

func stop_crouch() -> void:
	is_crouching = false
	set_slide_collision(false)

func set_slide_collision(active: bool) -> void:
	# Wyłączamy/włączamy górną kolizję
	upper_collision.disabled = active

	if active:
		pivot.scale.y = 0.5
		pivot.position.y = 0.0
	else:
		if not is_ceiling_above():
			pivot.scale.y = 1.0
			pivot.position.y = 0.0
		else:
			# Bezpiecznik: jeśli sufit, zostań w kucnięciu
			is_crouching = true
			upper_collision.disabled = true

func handle_normal_movement(delta: float, direction: Vector3) -> void:
	handle_momentum(delta, direction)
	if direction.length() > 0:
		velocity.x = move_toward(velocity.x, direction.x * current_target_speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * current_target_speed, acceleration * delta)
		pivot.rotation.y = lerp_angle(pivot.rotation.y, atan2(direction.x, direction.z), 15 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		velocity.z = move_toward(velocity.z, 0, friction * delta)

func handle_crouch_movement(delta: float, direction: Vector3) -> void:
	var crouch_speed = base_speed * 0.8
	velocity.x = move_toward(velocity.x, direction.x * crouch_speed, acceleration * delta)
	velocity.z = move_toward(velocity.z, direction.z * crouch_speed, acceleration * delta)
	if direction.length() > 0:
		pivot.rotation.y = lerp_angle(pivot.rotation.y, atan2(direction.x, direction.z), 10 * delta)

func apply_air_movement(delta: float, direction: Vector3) -> void:
	if direction.length() > 0:
		velocity.x += direction.x * acceleration * air_control * delta
		velocity.z += direction.z * acceleration * air_control * delta
		var h_vel = Vector2(velocity.x, velocity.z).limit_length(max(current_target_speed, Vector2(velocity.x, velocity.z).length()))
		velocity.x = h_vel.x
		velocity.z = h_vel.y

func handle_momentum(delta: float, direction: Vector3) -> void:
	is_sprinting = Input.is_action_pressed("sprint")
	var base = sprint_speed if is_sprinting else base_speed
	if direction.length() > 0:
		momentum = move_toward(momentum, max_momentum_speed - base, momentum_gain_rate * delta)
	else:
		momentum = move_toward(momentum, 0, friction * 0.2 * delta)
	current_target_speed = base + momentum

func is_ceiling_above() -> bool:
	if ceiling_ray:
		ceiling_ray.force_raycast_update()
		return ceiling_ray.is_colliding()
	return false

func get_gravity_value() -> float:
	return ProjectSettings.get_setting("physics/3d/default_gravity")
