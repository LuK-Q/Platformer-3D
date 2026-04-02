extends State

var vault_cooldown: float = 0.0

func enter() -> void:
	#Reset parametrów
	player.anim_tree.set("parameters/conditions/is_on_floor", true)
	player.anim_tree.set("parameters/conditions/is_crouching", false)
	player.anim_tree.set("parameters/conditions/is_not_crouching", true)
	
	var prev_state_name = ""
	if state_machine.previous_state:
		prev_state_name = state_machine.previous_state.name.to_lower()
		
	if prev_state_name != "airborne":
		player.state_machine_playback.travel("Grounded")

func physics_update(delta: float) -> void:
	if vault_cooldown > 0:
		vault_cooldown -= delta
		
	if not player.is_on_floor():
		state_machine.transition_to("Airborne")
		return

	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = get_camera_relative_direction(input_dir)
	var is_sprinting = Input.is_action_pressed("sprint")
	var target_speed = player.run_speed if is_sprinting else player.walk_speed
	
	if direction.length() > 0:
		player.velocity.x = direction.x * target_speed
		player.velocity.z = direction.z * target_speed
		
		player.pivot.rotation.y = lerp_angle(player.pivot.rotation.y, atan2(direction.x, direction.z), 15 * delta)
	else:
		player.velocity.x = move_toward(player.velocity.x, 0, player.friction * delta)
		player.velocity.z = move_toward(player.velocity.z, 0, player.friction * delta)

	# OBSŁUGA SKOKU I VAULT
	if Input.is_action_just_pressed("jump"):
		if check_vault_opportunity():
			return 
		
		player.velocity.y = player.jump_velocity
		
		if is_sprinting and direction.length() > 0:
			player.state_machine_playback.travel("Running Jump")
		else:
			player.state_machine_playback.travel("Jump_start")
			
		state_machine.transition_to("Airborne")
		return

	# Obsługa Crouch/Slide
	if Input.is_action_just_pressed("crouch"):
		if is_sprinting and direction.length() > 0:
			state_machine.transition_to("Sliding")
		else:
			state_machine.transition_to("Crouching")
		return
	
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

func check_vault_opportunity() -> bool:
	if vault_cooldown > 0:
		return false
	# prędkość pozioma, żeby nie robić przeskoku w miejscu
	if player.velocity.length() < 2.0:
		return false
	
	player.HighWallRay.force_raycast_update()
	if player.HighWallRay.is_colliding():
		return false
	
	var forward_cast = player.get_node("Pivot/VaultForwardCast") 
	var height_node = player.get_node("Pivot/VaultHeightNode")
	var height_ray = height_node.get_node("VaultHeightRay") 
	
	forward_cast.force_shapecast_update()
	
	if forward_cast.is_colliding():
		
		var original_local_pos = height_node.position
		var hit_point = forward_cast.get_collision_point(0)
		var forward_dir = player.pivot.global_transform.basis.z 
		var probe_position = hit_point + (forward_dir * 0.1) 

		height_node.global_position = Vector3(probe_position.x, height_node.global_position.y, probe_position.z)
		height_ray.force_raycast_update()
		
		var can_vault = false
		
		if height_ray.is_colliding():
			var top_hit_point = height_ray.get_collision_point()
			var obstacle_height = top_hit_point.y - player.global_position.y
			
			# wysokości przeszkody
			if obstacle_height > 0.4 and obstacle_height < 1.6:
				can_vault = true
				
		height_node.position = original_local_pos
		if can_vault:
			state_machine.transition_to("Vaulting")
			return true 
			
	return false
