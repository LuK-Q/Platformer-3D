extends State

# Grounded obsługuje: Chodzenie, Bieganie, Rotację i inteligentne wyjścia.

func enter() -> void:
	# 1. ZAWSZE resetujemy parametry postawy przy wejściu na ziemię.
	# Dzięki temu, niezależnie skąd przychodzimy (kucanie, wślizg, powietrze),
	# drzewo animacji wie, że fizycznie już stoimy/biegniemy.
	player.anim_tree.set("parameters/conditions/is_on_floor", true)
	player.anim_tree.set("parameters/conditions/is_crouching", false)
	player.anim_tree.set("parameters/conditions/is_not_crouching", true)
	
	# 2. Pobieramy nazwę poprzedniego stanu
	var prev_state_name = ""
	if state_machine.previous_state:
		prev_state_name = state_machine.previous_state.name.to_lower()
		
	# 3. Zabezpieczenie Xfade (Ochrona przed Double-Travel)
	# Jeśli przyszliśmy z powietrza, AirborneState już odpalił travel("Grounded").
	# W każdym innym przypadku (np. powrót z Crouching), musimy wywołać to ręcznie.
	if prev_state_name != "airborne":
		player.state_machine_playback.travel("Grounded")

func physics_update(delta: float) -> void:
	# 1. Stabilizacja i grawitacja (Docisk do podłoża)
	if not player.is_on_floor():
		state_machine.transition_to("Airborne")
		return

	# 2. Odczyt Inputu
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = get_camera_relative_direction(input_dir)
	var is_sprinting = Input.is_action_pressed("sprint")
	
	# 3. Logika Ruchu (Instant Velocity)
	# Skoro nie budujemy pędu, przypisujemy prędkość bezpośrednio lub z bardzo wysokim acceleration
	var target_speed = player.run_speed if is_sprinting else player.walk_speed
	
	if direction.length() > 0:
		player.velocity.x = direction.x * target_speed
		player.velocity.z = direction.z * target_speed
		
		# Obrót Pivotu (+Z przód)
		player.pivot.rotation.y = lerp_angle(player.pivot.rotation.y, atan2(direction.x, direction.z), 15 * delta)
	else:
		# Natychmiastowe zatrzymanie (lub szybkie wygaszenie friction)
		player.velocity.x = move_toward(player.velocity.x, 0, player.friction * delta)
		player.velocity.z = move_toward(player.velocity.z, 0, player.friction * delta)

	# 4. Obsługa Skoku (Jump Split)
	if Input.is_action_just_pressed("jump"):
		player.velocity.y = player.jump_velocity
		
		# Wybieramy animację na bazie aktualnego pędu
		if is_sprinting and direction.length() > 0:
			player.state_machine_playback.travel("Running Jump")
		else:
			player.state_machine_playback.travel("Jump_start")
			
		state_machine.transition_to("Airborne")
		return

	# 5. Obsługa Kucania/Wślizgu
	if Input.is_action_just_pressed("crouch"):
		if is_sprinting and direction.length() > 0:
			state_machine.transition_to("Sliding")
		else:
			state_machine.transition_to("Crouching")
		return

	# 6. Finalizacja
	player.move_and_slide()
	update_animations(direction.length() > 0, is_sprinting)

func get_camera_relative_direction(input_dir: Vector2) -> Vector3:
	var cam_basis = player.camera_node.global_transform.basis
	var forward = Vector3(cam_basis.z.x, 0, cam_basis.z.z).normalized()
	var right = Vector3(cam_basis.x.x, 0, cam_basis.x.z).normalized()
	return (forward * input_dir.y + right * input_dir.x).normalized()

func update_animations(is_moving: bool, is_sprinting: bool) -> void:
	var target_blend = 0.0
	if is_moving:
		target_blend = 1.0 if is_sprinting else 0.5
	
	var current_blend = player.anim_tree.get("parameters/Grounded/Movement/blend_position")
	var new_blend = lerp(current_blend, float(target_blend), 0.15)
	player.anim_tree.set("parameters/Grounded/Movement/blend_position", new_blend)
