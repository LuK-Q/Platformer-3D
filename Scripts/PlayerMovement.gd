extends CharacterBody3D

#region EXPORTED VARIABLES
@export_group("Movement")
@export var walk_speed := 3.0
@export var run_speed := 6.0
@export var acceleration := 50.0 # Wysoka wartość = natychmiastowy start
@export var friction := 60.0     # Wysoka wartość = brak ślizgania przy zatrzymaniu
@export var air_control := 0.1

@export_group("Jump & Gravity")
@export var jump_velocity := 5.0
@export var gravity_multiplier := 2
@export var fall_gravity_multiplier := 3.0
@export var hard_land_threshold := -6.0 # Prędkość Y, przy której następuje stun

@export_group("Sliding & Crouching")
@export var slide_speed_multiplier := 1.4
@export var slide_friction := 5.0
@export var slide_timer_max := 1.2
@export var slide_activation_threshold := 5.0
#endregion

#region NODE REFERENCES
# --- REFERENCJE ---
@onready var pivot: Node3D = $Pivot
@onready var camera_node: Camera3D = get_viewport().get_camera_3d()
@onready var ceiling_ray: RayCast3D = $Pivot/CeilingRay
@onready var VaultRay: RayCast3D = $Pivot/VaultRay
@onready var WallRayRight: RayCast3D = $Pivot/WallRayRight
@onready var WallRayLeft: RayCast3D = $Pivot/WallRayLeft
@onready var lower_collision: CollisionShape3D = $LowerCollision
@onready var upper_collision: CollisionShape3D = $UpperCollision
@onready var landing_ray: RayCast3D = $Pivot/landing_ray
@onready var anim_tree: AnimationTree = $Pivot/playerModel/AnimationTree
@onready var state_machine : AnimationNodeStateMachinePlayback = anim_tree.get("parameters/playback")
#endregion

#region LOCAL VARIABLES
# --- ZMIENNE STANU ---
enum State {
	GROUNDED,      # Idle, Walk, Run
	AIRBORNE,      # Skok, Opadanie
	CROUCHING,     # Kucanie i chodzenie w kuckach
	SLIDING,       # Wślizg
	HARD_LANDING,  # Stun po upadku
	# Przyszłe stany przygotowane do implementacji:
	VAULTING,
	WALL_RUNNING,
	LEDGE_HANGING,
	LEDGE_MOVING
}

var current_state: State = State.GROUNDED
var previous_state: State = State.GROUNDED

var current_blend := 0.0
var wants_to_roll := false 
var land_velocity := 0.0   
var slide_timer := 0.0
#endregion

func _ready() -> void:
	anim_tree.active = true

func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var cam_basis := camera_node.global_transform.basis
	var forward := Vector3(cam_basis.z.x, 0, cam_basis.z.z).normalized()
	var right := Vector3(cam_basis.x.x, 0, cam_basis.x.z).normalized()
	var direction := (forward * input_dir.y + right * input_dir.x).normalized()
	
	var horizontal_speed = Vector2(velocity.x, velocity.z).length()
	
	# Raycast antycypacji lądowania
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

	move_and_slide()
	update_animations()

#region FUNKCJE OBSŁUGI POSTACI
func process_grounded(delta: float, direction: Vector3, speed: float) -> void:
	if not is_on_floor():
		change_state(State.AIRBORNE)
		return

	# WEJŚCIE W KUCANIE LUB WŚLIZG
	if Input.is_action_just_pressed("crouch"):
		if Input.is_action_pressed("sprint") and speed > slide_activation_threshold:
			change_state(State.SLIDING)
		else:
			change_state(State.CROUCHING)
		return

	if Input.is_action_just_pressed("jump"):
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
	land_velocity = velocity.y # Zapisujemy prędkość na wypadek twardego lądowania

	if is_on_floor():
		# Sprawdzamy, czy uderzyliśmy o ziemię zbyt mocno
		if land_velocity < hard_land_threshold and not wants_to_roll:
			change_state(State.HARD_LANDING)
		else:
			change_state(State.GROUNDED)
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

	# WYJŚCIE Z KUCANIA (sprawdzamy też raycast sufitu!)
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
	
	# SKOK ZE WŚLIZGU
	if Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity * 0.8
		change_state(State.AIRBORNE)
		state_machine.travel("Jump_start") # Wymuszamy przejście w animacji
		return
	
	# KONIEC WŚLIZGU
	if slide_timer <= 0:
		if Input.is_action_pressed("crouch") or is_ceiling_above():
			change_state(State.CROUCHING)
		else:
			change_state(State.GROUNDED)

func process_hard_landing(delta: float) -> void:
	# Stun - postać się zatrzymuje
	velocity.x = move_toward(velocity.x, 0, friction * delta)
	velocity.z = move_toward(velocity.z, 0, friction * delta)
	
	# Zabezpieczenie: Jeśli animacja Hard Landing się skończyła (lub z jakiegoś powodu drzewo ją pominęło), wracamy
	if state_machine.get_current_node() != "hard landing" and is_on_floor():
		change_state(State.GROUNDED)
#endregion

#region FUNKCJE ZMIANY STANÓW
############################### --- FUNKCJA ZARZĄDZAJĄCA ZMIANĄ STANU ---

func change_state(new_state: State) -> void:
	if current_state == new_state:
		return
		
	previous_state = current_state
	current_state = new_state
	
	# Logika wykonywana RAZ przy WEJŚCIU w dany stan (np. zmiana kolizji)
	match current_state:
		State.SLIDING:
			slide_timer = slide_timer_max
			upper_collision.disabled = true
			velocity.x *= slide_speed_multiplier
			velocity.z *= slide_speed_multiplier
		State.CROUCHING:
			upper_collision.disabled = true
		State.GROUNDED, State.AIRBORNE:
			# Gdy wracamy do normalnego stania/lotu, upewniamy się, że kolizja wraca
			if upper_collision.disabled and not is_ceiling_above():
				upper_collision.disabled = false
#endregion

#region FUNKCJE ZMIANY ANIMACJI
############################### --- FUNKCJE ZARZĄDZANIA ANIMACJAMI ---

func update_animations() -> void:
	var h_speed = Vector2(velocity.x, velocity.z).length()
	var is_moving = h_speed > 0.1
	var is_sprinting = Input.is_action_pressed("sprint")
	
	var walk_blend = 0.0
	if is_moving:
		walk_blend = 1.0 if is_sprinting else 0.5
	anim_tree.set("parameters/Grounded/Ground movement/blend_position", walk_blend)
	
	# Uznajemy postać za "na podłodze", jeśli jest w jakimkolwiek stanie naziemnym
	var is_ground_state = current_state in [State.GROUNDED, State.CROUCHING, State.SLIDING, State.HARD_LANDING]
	anim_tree.set("parameters/conditions/is_on_floor", is_ground_state)
	anim_tree.set("parameters/conditions/is_airborne", current_state == State.AIRBORNE)
	
	# Logika rzutowania stanów na drzewo
	anim_tree.set("parameters/conditions/is_crouching", current_state == State.CROUCHING)
	anim_tree.set("parameters/conditions/is_not_crouching", current_state != State.CROUCHING)
	
	anim_tree.set("parameters/conditions/is_sliding", current_state == State.SLIDING)
	anim_tree.set("parameters/conditions/is_hard_landing", current_state == State.HARD_LANDING)
	
	# Uproszczone kucanie z ruchem
	var is_crouch_walking = current_state == State.CROUCHING and is_moving
	anim_tree.set("parameters/conditions/is_crouch_walking", is_crouch_walking)
	anim_tree.set("parameters/conditions/is_not_crouch_walking", not is_crouch_walking)
#endregion

#region POZOSTAŁE FUNKCJE

############################### --- POZOSTAŁE FUNKCJE ---

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
