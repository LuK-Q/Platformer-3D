extends State

var wall_normal: Vector3
var run_direction: Vector3
var run_timer: float = 0.0
var side: int = 0 

func enter() -> void:
	# 1. Wybór strony i normalnej
	player.WallRayLeft.force_raycast_update()
	player.WallRayRight.force_raycast_update()
	
	if player.WallRayLeft.is_colliding():
		side = -1
		wall_normal = player.WallRayLeft.get_collision_normal()
		player.anim_tree.set("parameters/conditions/wall_run_left", true)
	else:
		side = 1
		wall_normal = player.WallRayRight.get_collision_normal()
		player.anim_tree.set("parameters/conditions/wall_run_right", true)
	
	# 2. Obliczanie kierunku biegu
	var forward = Vector3.UP.cross(wall_normal).normalized()
	if forward.dot(player.pivot.global_transform.basis.z) < 0:
		forward = -forward
	run_direction = forward
	
	# 3. Impuls w górę na start
	player.velocity.y = player.jump_velocity * 0.6 
	run_timer = player.wall_run_max_time 

func physics_update(delta: float) -> void:
	run_timer -= delta
	
	if player.is_on_floor():
		state_machine.transition_to("Grounded")
		return

	# --- AUTOMATYCZNY ODSKOK (Koniec czasu) ---
	if run_timer <= 0:
		perform_wall_jump(true) # true = auto-odskok
		return

	# --- MANUALNE PRZERWANIE (Kliknięcie Jump) ---
	if Input.is_action_just_pressed("jump"):
		perform_wall_jump(false) # false = manualny skok
		return

	# Sprawdzanie czy ściana nadal jest
	var current_ray = player.WallRayLeft if side == -1 else player.WallRayRight
	current_ray.force_raycast_update()
	if not current_ray.is_colliding():
		# WYMUSZAMY przejście do animacji spadania, zanim zmienimy stan
		player.state_machine_playback.travel("Falling")
		state_machine.transition_to("Airborne")
		return

	# Fizyka biegu
	var glue_force = -wall_normal * 3.0
	player.velocity.x = run_direction.x * player.run_speed + glue_force.x
	player.velocity.z = run_direction.z * player.run_speed + glue_force.z
	player.velocity.y -= (player.get_gravity_value() * 0.4) * delta
	
	var target_rotation = atan2(run_direction.x, run_direction.z)
	player.pivot.rotation.y = lerp_angle(player.pivot.rotation.y, target_rotation, 15 * delta)
	
	player.move_and_slide()

# Funkcja realizująca odskok i zmianę animacji
func perform_wall_jump(is_auto: bool) -> void:
	# --- PARAMETRY SIŁY (Możesz je edytować dla lepszego feelu) ---
	var forward_power = 2  # Jak bardzo postać leci do przodu
	var away_power = 1.7     # Jak lekko odskakuje od ściany (zmniejszone z 1.2)
	var up_power = 2.5       # Siła wybicia w górę
	
	# Jeśli to automatyczny odskok na końcu, możemy go nieco osłabić
	if is_auto:
		forward_power *= 0.8
		up_power *= 0.8

	# --- SKŁADANIE WEKTORA ---
	# Łączymy kierunek biegu, odbicie od ściany i wektor góra
	var jump_dir = (run_direction * forward_power + wall_normal * away_power + Vector3.UP * up_power).normalized()
	
	# Aplikujemy nową prędkość
	player.velocity = jump_dir * (player.jump_velocity * 1.5)
	
	var airborne = state_machine.get_node("Airborne")
	if airborne:
		airborne.wall_run_cooldown = 0.3 
	
	player.state_machine_playback.travel("Running Jump")
	state_machine.transition_to("Airborne")
	
func exit() -> void:
	# Resetujemy warunki w AnimationTree
	player.anim_tree.set("parameters/conditions/wall_run_left", false)
	player.anim_tree.set("parameters/conditions/wall_run_right", false)
