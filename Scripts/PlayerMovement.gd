extends CharacterBody3D

#region EXPORTED VARIABLES
@export_group("Movement")
@export var walk_speed := 3.0
@export var run_speed := 6.0
@export var acceleration := 50.0 
@export var friction := 60.0    
@export var air_control := 0.1

@export_group("Jump & Gravity")
@export var jump_velocity := 5.0
@export var gravity_multiplier := 2.0
@export var fall_gravity_multiplier := 3.0
@export var hard_land_threshold := -10.0 

@export_group("Sliding & Crouching")
@export var slide_speed_multiplier := 1.6
@export var slide_friction := 5.0
@export var slide_timer_max := 1.2
@export var slide_activation_threshold := 5.0
#endregion

#region NODE REFERENCES
@onready var pivot: Node3D = $Pivot
@onready var camera_node: Camera3D = get_viewport().get_camera_3d()
@onready var ceiling_ray: RayCast3D = $Pivot/CeilingRay
@onready var LowLedgeRay: RayCast3D = $Pivot/LowLedgeRay
@onready var HighWallRay: RayCast3D = $Pivot/HighWallRay
@onready var TopDownRay: RayCast3D = $Pivot/TopDownRay
@onready var WallRayRight: RayCast3D = $Pivot/WallRayRight
@onready var WallRayLeft: RayCast3D = $Pivot/WallRayLeft
@onready var LedgeGrabRay: RayCast3D = $Pivot/LedgeGrabRay
@onready var lower_collision: CollisionShape3D = $LowerCollision
@onready var upper_collision: CollisionShape3D = $UpperCollision
@onready var landing_ray: RayCast3D = $Pivot/landing_ray
@onready var anim_tree: AnimationTree = $Pivot/playerModel/AnimationTree
@onready var state_machine : AnimationNodeStateMachinePlayback = anim_tree.get("parameters/playback")
#endregion

#region LOCAL VARIABLES
enum State {
	GROUNDED,
	AIRBORNE,
	CROUCHING,
	SLIDING,
	HARD_LANDING,
	ROLLING,
	WALL_CLIMBING,
	VAULTING,
	WALL_RUNNING,
	LEDGE_HANGING,
	LEDGE_MOVING
}

var current_state: State = State.GROUNDED
var previous_state: State = State.GROUNDED

var current_blend := 0.0
var wants_to_roll := false 
var is_hard_landing := false 
var land_velocity := 0.0   
var slide_timer := 0.0
var is_running_jump_active := false 
var state_timer := 0.0
var vault_target_pos := Vector3.ZERO
var wall_normal := Vector3.ZERO
var climb_timer := 0.0
#endregion

func _ready() -> void:
	anim_tree.active = true

func _physics_process(delta: float) -> void:
	var input_dir := Vector2.ZERO
	if current_state not in [State.HARD_LANDING]: 
		input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")

	var cam_basis := camera_node.global_transform.basis
	var forward := Vector3(cam_basis.z.x, 0, cam_basis.z.z).normalized()
	var right := Vector3(cam_basis.x.x, 0, cam_basis.x.z).normalized()
	var direction := (forward * input_dir.y + right * input_dir.x).normalized()
	var horizontal_speed = Vector2(velocity.x, velocity.z).length()
	
	var is_about_to_land = landing_ray.is_colliding() and velocity.y < -1.0
	anim_tree.set("parameters/conditions/is_about_to_land", is_about_to_land)

	match current_state:
		State.GROUNDED:
			process_grounded(delta, direction, horizontal_speed)
		State.AIRBORNE:
			process_airborne(delta, direction)
		State.CROUCHING:
			process_crouching(delta, direction)
		State.SLIDING:
			process_sliding(delta)
		State.HARD_LANDING:
			process_hard_landing(delta)
		State.ROLLING:
			process_rolling(delta, direction) 
		State.VAULTING:
			process_vaulting(delta)
		State.WALL_CLIMBING:
			process_wall_climbing(delta)
		State.LEDGE_HANGING:
			process_ledge_hanging(delta)
			
	move_and_slide()
	update_animations()

#region FUNKCJE OBSŁUGI POSTACI
func process_grounded(delta: float, direction: Vector3, speed: float) -> void:
	if not is_on_floor():
		change_state(State.AIRBORNE)
		return

	if Input.is_action_just_pressed("crouch"):
		if Input.is_action_pressed("sprint") and speed > slide_activation_threshold:
			change_state(State.SLIDING)
		else:
			change_state(State.CROUCHING)
		return

	if Input.is_action_just_pressed("jump"):
		var is_moving = direction.length() > 0.1
		
		if is_moving and try_vault():
			return 
			
		if not is_moving and try_climb():
			return
			
		is_running_jump_active = Input.is_action_pressed("sprint") and speed > 1.0
		velocity.y = jump_velocity
		change_state(State.AIRBORNE)
		return
		
	var target_speed = run_speed if Input.is_action_pressed("sprint") else walk_speed
	if direction.length() > 0:
		velocity.x = move_toward(velocity.x, direction.x * target_speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * target_speed, acceleration * delta)
		pivot.rotation.y = lerp_angle(pivot.rotation.y, atan2(direction.x, direction.z), 15 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		velocity.z = move_toward(velocity.z, 0, friction * delta)

func process_airborne(delta: float, direction: Vector3) -> void:
	if is_on_wall():
		LowLedgeRay.force_raycast_update()
		HighWallRay.force_raycast_update()
		LedgeGrabRay.force_raycast_update()
		TopDownRay.force_raycast_update()
		
		var normal = get_wall_normal()
		var forward = pivot.global_transform.basis.z 
		
		if forward.dot(normal) < -0.6: 
			wall_normal = normal
			
			if LowLedgeRay.is_colliding() and HighWallRay.is_colliding() and not LedgeGrabRay.is_colliding() and TopDownRay.is_colliding():
				change_state(State.LEDGE_HANGING)
				return
				
			elif LowLedgeRay.is_colliding() and HighWallRay.is_colliding():
				if Input.is_action_pressed("move_forward"): 
					change_state(State.WALL_CLIMBING)
					return
					
	if velocity.y < land_velocity:
		land_velocity = velocity.y

	if Input.is_action_just_pressed("crouch"):
		wants_to_roll = true

	if is_on_floor():
		if wants_to_roll:
			change_state(State.ROLLING)
		elif land_velocity < hard_land_threshold:
			change_state(State.HARD_LANDING)
		else:
			change_state(State.GROUNDED)
		
		land_velocity = 0.0
		wants_to_roll = false
		return

	var grav = get_gravity_value() * (gravity_multiplier if velocity.y > 0 else fall_gravity_multiplier)
	velocity.y -= grav * delta

	if direction.length() > 0:
		velocity.x += direction.x * acceleration * air_control * delta
		velocity.z += direction.z * acceleration * air_control * delta

func process_crouching(delta: float, direction: Vector3) -> void:
	if not is_on_floor():
		change_state(State.AIRBORNE)
		return

	if not Input.is_action_pressed("crouch") and not is_ceiling_above():
		change_state(State.GROUNDED)
		return

	var crouch_speed = walk_speed * 0.6
	velocity.x = move_toward(velocity.x, direction.x * crouch_speed, acceleration * delta)
	velocity.z = move_toward(velocity.z, direction.z * crouch_speed, acceleration * delta)
	if direction.length() > 0:
		pivot.rotation.y = lerp_angle(pivot.rotation.y, atan2(direction.x, direction.z), 10 * delta)

func process_sliding(delta: float) -> void:
	slide_timer -= delta
	velocity.x = move_toward(velocity.x, 0, slide_friction * delta)
	velocity.z = move_toward(velocity.z, 0, slide_friction * delta)
	
	if Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity * 1.15
		change_state(State.AIRBORNE)
		state_machine.travel("Running Jump") 
		return
	
	if slide_timer <= 0:
		if Input.is_action_pressed("crouch") or is_ceiling_above():
			change_state(State.CROUCHING)
		else:
			change_state(State.GROUNDED)

func process_hard_landing(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, friction * 3 * delta)
	velocity.z = move_toward(velocity.z, 0, friction * 3 * delta)
	
	if state_timer > 0:
		state_timer -= delta 
	elif state_machine.get_current_node() != "hard landing" and is_on_floor():
		change_state(State.GROUNDED)

func process_rolling(delta: float, direction: Vector3) -> void:
	var roll_speed = run_speed * 0.6 
	var roll_dir = direction
	if roll_dir.length() == 0:
		roll_dir = Vector3(sin(pivot.rotation.y), 0, cos(pivot.rotation.y)).normalized()
	
	velocity.x = move_toward(velocity.x, roll_dir.x * roll_speed, acceleration * delta)
	velocity.z = move_toward(velocity.z, roll_dir.z * roll_speed, acceleration * delta)

	if direction.length() > 0:
		pivot.rotation.y = lerp_angle(pivot.rotation.y, atan2(direction.x, direction.z), 20 * delta)
	
	if state_timer > 0:
		state_timer -= delta
	elif state_machine.get_current_node() != "falling to roll" and is_on_floor():
		change_state(State.GROUNDED)

func process_vaulting(delta: float) -> void:
	velocity.y = 0 
	
	var forward_dir = pivot.global_transform.basis.z.normalized()
	velocity.x = forward_dir.x * walk_speed * 1.5
	velocity.z = forward_dir.z * walk_speed * 1.5
	
	if state_timer > 0:
		state_timer -= delta
	elif state_machine.get_current_node() != "Running vault":
		change_state(State.GROUNDED)

func process_wall_climbing(delta: float) -> void:
	climb_timer -= delta
	
	velocity.y = walk_speed * 1.3
	velocity.x = -wall_normal.x * 2.0
	velocity.z = -wall_normal.z * 2.0
	
	LowLedgeRay.force_raycast_update()
	HighWallRay.force_raycast_update()
	LedgeGrabRay.force_raycast_update()
	TopDownRay.force_raycast_update() 
	
	if LowLedgeRay.is_colliding() and not HighWallRay.is_colliding():
		if TopDownRay.is_colliding():
			vault_target_pos = TopDownRay.get_collision_point()
			change_state(State.VAULTING)
			return

	if not LedgeGrabRay.is_colliding() and HighWallRay.is_colliding() and TopDownRay.is_colliding():
		change_state(State.LEDGE_HANGING)
		return
		
	if climb_timer <= 0:
		velocity.x = wall_normal.x * 1.5 
		velocity.z = wall_normal.z * 1.5
		change_state(State.AIRBORNE)

func process_ledge_hanging(delta: float) -> void:
	if state_timer > 0:
		state_timer -= delta
		velocity = Vector3.ZERO
		return

	HighWallRay.force_raycast_update()
	if not HighWallRay.is_colliding():
		change_state(State.AIRBORNE)
		return

	velocity = Vector3.ZERO 
	
	# Utrzymanie postaci przodem do ściany podczas zwykłego wiszenia
	var target_rotation = atan2(-wall_normal.x, -wall_normal.z)
	pivot.rotation.y = lerp_angle(pivot.rotation.y, target_rotation, 15 * delta)

	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")

	# 2. Ruch po krawędzi fizycznie
	if input_dir.x < -0.1:
		var right_dir = Vector3.UP.cross(wall_normal).normalized()
		global_position += right_dir * input_dir.x * (walk_speed * 0.4) * delta
	elif input_dir.x > 0.1:
		var right_dir = Vector3.UP.cross(wall_normal).normalized()
		global_position += right_dir * input_dir.x * (walk_speed * 0.4) * delta

	# 3. Odbicie od ściany (S + Space)
	if Input.is_action_pressed("move_back") and Input.is_action_just_pressed("jump"):
		state_machine.travel("Jump From Ledge") 
		
		pivot.rotation.y = atan2(-wall_normal.x, -wall_normal.z)
		
		velocity = wall_normal * 4.0 
		velocity.y = jump_velocity * 0.8
		change_state(State.AIRBORNE)
		return

	# 4. Wejście na krawędź (W + Space)
	if Input.is_action_pressed("move_forward") and Input.is_action_just_pressed("jump"):
		state_machine.travel("Ledge climb up")
		state_timer = 0.5 
		
		var tween = get_tree().create_tween()
		var up_position = global_position + Vector3(0, 2.2, 0) 
		var forward_position = up_position + (pivot.global_transform.basis.z * 1.2)
		
		tween.tween_property(self, "global_position", up_position, 0.3)
		tween.tween_property(self, "global_position", forward_position, 0.2)
		tween.tween_callback(func(): change_state(State.GROUNDED))

#endregion

#region FUNKCJE ZMIANY STANÓW
func change_state(new_state: State) -> void:
	if current_state == new_state:
		return
		
	previous_state = current_state
	current_state = new_state
	
	match current_state:
		State.WALL_CLIMBING:
			climb_timer = 0.2 
			state_machine.travel("Wall Run Forward and grab ledge") 
		State.LEDGE_HANGING:
			state_machine.travel("Hanging Idle")
			velocity = Vector3.ZERO
			lower_collision.disabled = true
			state_timer = 0.0 
		State.VAULTING:
			state_timer = 0.1 
			state_machine.travel("Running vault") 
			lower_collision.disabled = true 
			upper_collision.disabled = true 
		State.HARD_LANDING:
			velocity.x = 0
			velocity.z = 0
			state_timer = 0.1 
			state_machine.travel("hard landing") 
		State.ROLLING:
			state_timer = 0.1
			state_machine.travel("falling to roll")
		State.SLIDING:
			slide_timer = slide_timer_max
			upper_collision.disabled = true
			velocity.x *= slide_speed_multiplier
			velocity.z *= slide_speed_multiplier
		State.CROUCHING:
			upper_collision.disabled = true
		State.GROUNDED, State.AIRBORNE:
			if upper_collision.disabled and not is_ceiling_above():
				upper_collision.disabled = false
			if lower_collision.disabled: 
				lower_collision.disabled = false 
#endregion

#region FUNKCJE ZMIANY ANIMACJI
func update_animations() -> void:
	var h_speed = Vector2(velocity.x, velocity.z).length()
	var is_moving = h_speed > 0.1
	var is_sprinting = Input.is_action_pressed("sprint")
	
	var target_blend = 0.0
	if is_moving:
		target_blend = 1.0 if is_sprinting else 0.5
	var lerp_speed = 10.0 
	current_blend = lerp(current_blend, target_blend, get_physics_process_delta_time() * lerp_speed)	
	anim_tree.set("parameters/Grounded/Movement/blend_position", current_blend)
	
	# Zmienne podstawowe stanów
	var is_hanging = current_state == State.LEDGE_HANGING
	var is_vaulting = current_state == State.VAULTING
	var is_climbing_wall = current_state == State.WALL_CLIMBING
	var is_sliding_state = current_state == State.SLIDING
	
	# Restrykcyjne zabezpieczenie stanów podłogi i opadania.
	# Zapewnia, że drzewo nie zepsuje animacji krawędzi lub wspinaczki!
	var is_ground_state = false
	var is_falling = false
	var is_jumping = false
	
	if not is_hanging and not is_vaulting and not is_climbing_wall:
		is_ground_state = current_state in [State.GROUNDED, State.CROUCHING, State.HARD_LANDING, State.ROLLING]
		is_falling = current_state == State.AIRBORNE and velocity.y <= 0.0
		is_jumping = current_state == State.AIRBORNE and velocity.y > 0.0

	# Warunki dla ruchu po krawędzi
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back") if is_hanging else Vector2.ZERO
	var is_ledge_moving_left = is_hanging and input_dir.x < -0.1
	var is_ledge_moving_right = is_hanging and input_dir.x > 0.1
	var is_hanging_idle = is_hanging and not is_ledge_moving_left and not is_ledge_moving_right
	
	# Warunek dołączenia do biegu po ścianie
	var is_run_climbing = is_climbing_wall

	# Wysłanie parametrów do AnimationTree
	anim_tree.set("parameters/conditions/is_on_floor", is_ground_state)
	anim_tree.set("parameters/conditions/is_jumping", is_jumping and not is_running_jump_active)
	anim_tree.set("parameters/conditions/is_running_jump", is_jumping and is_running_jump_active)
	anim_tree.set("parameters/conditions/is_falling", is_falling)
	
	anim_tree.set("parameters/conditions/is_crouching", current_state == State.CROUCHING)
	anim_tree.set("parameters/conditions/is_not_crouching", current_state != State.CROUCHING)
	anim_tree.set("parameters/conditions/is_hard_landing", current_state == State.HARD_LANDING)
	
	anim_tree.set("parameters/conditions/is_hanging", is_hanging)
	anim_tree.set("parameters/conditions/is_ledge_moving_left", is_ledge_moving_left)
	anim_tree.set("parameters/conditions/is_ledge_moving_right", is_ledge_moving_right)
	anim_tree.set("parameters/conditions/is_hanging_idle", is_hanging_idle)
	
	anim_tree.set("parameters/conditions/is_vaulting", is_vaulting)
	anim_tree.set("parameters/conditions/is_climbing_wall", is_climbing_wall)
	anim_tree.set("parameters/conditions/is_run_climbing", is_run_climbing)
	anim_tree.set("parameters/conditions/is_sliding", is_sliding_state)
	
	var is_crouch_walking = current_state == State.CROUCHING and is_moving
	anim_tree.set("parameters/conditions/is_crouch_walking", is_crouch_walking)
	anim_tree.set("parameters/conditions/is_not_crouch_walking", not is_crouch_walking)
#endregion

#region POZOSTAŁE FUNKCJE
func try_climb() -> bool:
	LowLedgeRay.force_raycast_update()
	HighWallRay.force_raycast_update()
	LedgeGrabRay.force_raycast_update()
	TopDownRay.force_raycast_update()

	if LowLedgeRay.is_colliding() and HighWallRay.is_colliding() and not LedgeGrabRay.is_colliding() and TopDownRay.is_colliding():
		var normal = HighWallRay.get_collision_normal()
		var forward = pivot.global_transform.basis.z 
		
		if forward.dot(normal) < -0.7:
			wall_normal = normal
			change_state(State.LEDGE_HANGING)
			return true
			
	return false

func try_vault() -> bool:
	LowLedgeRay.force_raycast_update()
	HighWallRay.force_raycast_update()
	TopDownRay.force_raycast_update()

	if LowLedgeRay.is_colliding() and not HighWallRay.is_colliding():
		change_state(State.VAULTING)
		return true 
			
	return false 

func handle_crouch_movement(delta: float, direction: Vector3) -> void:
	var crouch_speed = walk_speed * 0.6
	velocity.x = move_toward(velocity.x, direction.x * crouch_speed, acceleration * delta)
	velocity.z = move_toward(velocity.z, direction.z * crouch_speed, acceleration * delta)
	if direction.length() > 0:
		pivot.rotation.y = lerp_angle(pivot.rotation.y, atan2(direction.x, direction.z), 10 * delta)

func is_ceiling_above() -> bool:
	if ceiling_ray:
		ceiling_ray.force_raycast_update()
		return ceiling_ray.is_colliding()
	return false

func apply_gravity(delta: float) -> void:
	var grav = get_gravity_value() * (gravity_multiplier if velocity.y > 0 else fall_gravity_multiplier)
	velocity.y -= grav * delta

func get_gravity_value() -> float:
	return ProjectSettings.get_setting("physics/3d/default_gravity")
#endregion
