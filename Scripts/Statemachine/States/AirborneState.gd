extends State

var fall_speed: float = 0.0
var wall_run_cooldown: float = 0.0

func enter() -> void:
	player.anim_tree.set("parameters/conditions/is_on_floor", false)
	fall_speed = 0.0

	player.anim_tree.set("parameters/conditions/do_soft_land", false)
	player.anim_tree.set("parameters/conditions/do_normal_land", false)
	player.anim_tree.set("parameters/conditions/do_hard_land", false)

func physics_update(delta: float) -> void:
	if wall_run_cooldown > 0:
		wall_run_cooldown -= delta
	# 1. Zabezpieczenie przed 1-klatkowym błędem wznoszenia
	if player.is_on_floor() and player.velocity.y <= 0.0:
		
		# Resetujemy wszystkie włączniki lądowania na wszelki wypadek
		player.anim_tree.set("parameters/conditions/do_soft_land", false)
		player.anim_tree.set("parameters/conditions/do_normal_land", false)
		player.anim_tree.set("parameters/conditions/do_hard_land", false)

		# Mózg decyduje, który włącznik aktywować na bazie pędu
		if fall_speed > player.soft_land_threshold:
			player.anim_tree.set("parameters/conditions/do_soft_land", true)
		elif fall_speed < player.hard_land_threshold:
			player.anim_tree.set("parameters/conditions/do_hard_land", true)
		else:
			player.anim_tree.set("parameters/conditions/do_normal_land", true)
			
		state_machine.transition_to("Grounded")
		return
	# 2. Aplikacja Grawitacji
	apply_gravity(delta)

	# 3. Air Control
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = get_camera_relative_direction(input_dir)
	
	if direction.length() > 0:
		player.velocity.x += direction.x * player.acceleration * player.air_control * delta
		player.velocity.z += direction.z * player.acceleration * player.air_control * delta

	# 4. Skanowanie Parkouru
	check_parkour_opportunities()

	# 5. Zapisanie prędkości PRZED zderzeniem z ziemią
	fall_speed = player.velocity.y
	
	# 6. Ruch
	player.move_and_slide()

func apply_gravity(delta: float) -> void:
	var grav = player.get_gravity_value()
	# Grawitacja ciągnie mocniej podczas opadania (lepszy "game feel")
	var multiplier = player.gravity_multiplier if player.velocity.y > 0 else player.fall_gravity_multiplier
	player.velocity.y -= grav * multiplier * delta

func get_camera_relative_direction(input_dir: Vector2) -> Vector3:
	var cam_basis = player.camera_node.global_transform.basis
	var forward = Vector3(cam_basis.z.x, 0, cam_basis.z.z).normalized()
	var right = Vector3(cam_basis.x.x, 0, cam_basis.x.z).normalized()
	return (forward * input_dir.y + right * input_dir.x).normalized()

func check_parkour_opportunities() -> void:
	# --- 1. LEDGE GRAB (Zostawiamy w spokoju) ---
	player.HighWallRay.force_raycast_update()
	player.LowLedgeRay.force_raycast_update()
	
	if player.LowLedgeRay.is_colliding() and not player.HighWallRay.is_colliding():
		var normal = player.LowLedgeRay.get_collision_normal()
		var forward_vec = player.pivot.global_transform.basis.z 
		
		if forward_vec.dot(normal) < -0.5:
			state_machine.transition_to("LedgeHanging")
			return

	# --- 2. WALL RUN (Tutaj wklejamy Twój nowy warunek) ---
	
	# Najpierw sprawdzamy legalność poprzedniego stanu (zostaje)
	var prev_state_name = ""
	if state_machine.previous_state:
		prev_state_name = state_machine.previous_state.name.to_lower()
		
	var allowed_states = ["grounded", "sliding", "wallrunning"]
	if not prev_state_name in allowed_states:
		return

	# Zabezpieczenie przed pionowym spadkiem (zostaje)
	if player.velocity.y < player.wall_run_arrival_v_limit:
		return

	# TUTAJ ZNAJDUJE SIĘ TWÓJ KOD Z COOLDOWNEM:
	if wall_run_cooldown <= 0:
		var left_hit = player.WallRayLeft.is_colliding()
		var right_hit = player.WallRayRight.is_colliding()
		
		if (left_hit or right_hit) and Input.is_action_pressed("move_forward"):
			state_machine.transition_to("WallRunning")
			return
