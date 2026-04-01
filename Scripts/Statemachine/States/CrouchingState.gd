extends State

func enter() -> void:
	player.upper_collision.set_deferred("disabled", true)
	
	# Mózg włącza warunki. Tryb "Auto" w drzewie sam nałoży xfade.
	player.anim_tree.set("parameters/conditions/is_crouching", true)
	player.anim_tree.set("parameters/conditions/is_not_crouching", false)

func physics_update(delta: float) -> void:
	# 1. Zabezpieczenie przed spadkiem
	if not player.is_on_floor():
		state_machine.transition_to("Airborne")
		return

	# 2. Próba wstania
	if not Input.is_action_pressed("crouch"):
		player.ceiling_ray.force_raycast_update()
		if not player.is_ceiling_above():
			state_machine.transition_to("Grounded")
			return

	# 3. Odczyt Inputu
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = get_camera_relative_direction(input_dir)
	var is_moving = direction.length() > 0
	
# 4. Sterowanie nowym BlendSpace kucania (Zamiast travel())
	var target_blend = 1.0 if is_moving else 0.0
	
	# Bezpieczne pobranie wartości (zwróci 0.0 zamiast crasha, jeśli ścieżka jest zła)
	var blend_param = player.anim_tree.get("parameters/Crouching/blend_position")
	var current_blend = float(blend_param) if blend_param != null else 0.0
	
	var new_blend = lerp(current_blend, float(target_blend), 0.15)
	player.anim_tree.set("parameters/Crouching/blend_position", new_blend)
	# 5. Fizyka Ruchu
	var current_crouch_speed = player.walk_speed * 0.5 

	if is_moving:
		player.velocity.x = direction.x * current_crouch_speed
		player.velocity.z = direction.z * current_crouch_speed
		player.pivot.rotation.y = lerp_angle(player.pivot.rotation.y, atan2(direction.x, direction.z), 15 * delta)
	else:
		player.velocity.x = move_toward(player.velocity.x, 0, player.friction * delta)
		player.velocity.z = move_toward(player.velocity.z, 0, player.friction * delta)

	player.move_and_slide()

func exit() -> void:
	player.upper_collision.set_deferred("disabled", false)
	
	# Przy wyjściu wyłączamy kucanie - drzewo automatycznie wykona xfade z powrotem do Grounded
	player.anim_tree.set("parameters/conditions/is_crouching", false)
	player.anim_tree.set("parameters/conditions/is_not_crouching", true)

func get_camera_relative_direction(input_dir: Vector2) -> Vector3:
	var cam_basis = player.camera_node.global_transform.basis
	var forward = Vector3(cam_basis.z.x, 0, cam_basis.z.z).normalized()
	var right = Vector3(cam_basis.x.x, 0, cam_basis.x.z).normalized()
	return (forward * input_dir.y + right * input_dir.x).normalized()
