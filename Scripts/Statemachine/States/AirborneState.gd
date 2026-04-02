extends State

var fall_speed: float = 0.0
var wall_run_cooldown: float = 0.0
var vertical_wall_run_cooldown: float = 0.0
var vault_cooldown: float = 0.0

func enter() -> void:
	player.anim_tree.set("parameters/conditions/is_on_floor", false)
	fall_speed = 0.0

	player.anim_tree.set("parameters/conditions/do_soft_land", false)
	player.anim_tree.set("parameters/conditions/do_normal_land", false)
	player.anim_tree.set("parameters/conditions/do_hard_land", false)

func physics_update(delta: float) -> void:
	if wall_run_cooldown > 0:
		wall_run_cooldown -= delta
		
	if vertical_wall_run_cooldown > 0:
		vertical_wall_run_cooldown -= delta
	
	if vault_cooldown > 0:
		vault_cooldown -= delta
	
	# Zabezpieczenie przed 1-klatkowym błędem wznoszenia i obsługa lądowania
	if player.is_on_floor() and player.velocity.y <= 0.0:
		
		if Input.is_action_pressed("crouch") and fall_speed < player.roll_threshold:
			state_machine.transition_to("Rolling")
			return
		
		if Input.is_action_pressed("crouch"):
			state_machine.transition_to("Crouching")
			return
			
		player.anim_tree.set("parameters/conditions/do_soft_land", false)
		player.anim_tree.set("parameters/conditions/do_normal_land", false)
		player.anim_tree.set("parameters/conditions/do_hard_land", false)

		#Obsługa poziomów upadku
		if fall_speed < player.hard_land_threshold:
			player.anim_tree.set("parameters/conditions/do_hard_land", true)
			state_machine.transition_to("HardLanding")
		else:
			if fall_speed > player.soft_land_threshold:
				player.anim_tree.set("parameters/conditions/do_soft_land", true)
			else:
				player.anim_tree.set("parameters/conditions/do_normal_land", true)
			state_machine.transition_to("Grounded")
			
		return
		
	apply_gravity(delta)
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = get_camera_relative_direction(input_dir)
	
	if direction.length() > 0:
		player.velocity.x += direction.x * player.acceleration * player.air_control * delta
		player.velocity.z += direction.z * player.acceleration * player.air_control * delta

	check_parkour_opportunities()
	# Zapisanie prędkości PRZED zderzeniem z ziemią
	fall_speed = player.velocity.y
	player.move_and_slide()

func apply_gravity(delta: float) -> void:
	var grav = player.get_gravity_value()
	var multiplier = player.gravity_multiplier if player.velocity.y > 0 else player.fall_gravity_multiplier
	player.velocity.y -= grav * multiplier * delta

func get_camera_relative_direction(input_dir: Vector2) -> Vector3:
	var cam_basis = player.camera_node.global_transform.basis
	var forward = Vector3(cam_basis.z.x, 0, cam_basis.z.z).normalized()
	var right = Vector3(cam_basis.x.x, 0, cam_basis.x.z).normalized()
	return (forward * input_dir.y + right * input_dir.x).normalized()

func check_parkour_opportunities() -> void:

	if Input.is_action_pressed("move_forward"):
		if check_vault_opportunity():
			return

	var prev_state_name = ""
	if state_machine.previous_state:
		prev_state_name = state_machine.previous_state.name.to_lower()
		
	var allowed_states = ["grounded", "sliding", "rolling", "wallrunning", "wallrunvertical"]
	if not prev_state_name in allowed_states:
		return

	if player.velocity.y < player.wall_run_arrival_v_limit:
		return

	if vertical_wall_run_cooldown <= 0:
		player.HighWallRay.force_raycast_update()
		if player.HighWallRay.is_colliding() and Input.is_action_pressed("move_forward"):
			var normal = player.HighWallRay.get_collision_normal()
			var forward_vec = player.pivot.global_transform.basis.z
			
			if forward_vec.dot(normal) < -0.8:
				state_machine.transition_to("WallRunVertical")
				return

	if wall_run_cooldown <= 0:
		var left_hit = player.WallRayLeft.is_colliding()
		var right_hit = player.WallRayRight.is_colliding()
		
		if (left_hit or right_hit) and Input.is_action_pressed("move_forward"):
			state_machine.transition_to("WallRunning")
			return

func check_vault_opportunity() -> bool:
	if vault_cooldown > 0:
		return false
	var horizontal_speed = Vector3(player.velocity.x, 0, player.velocity.z).length()
	if horizontal_speed < 2.0:
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
			
			if obstacle_height > 0.4 and obstacle_height <= 1.6:
				can_vault = true
				
		height_node.position = original_local_pos
		
		if can_vault:
			state_machine.transition_to("Vaulting")
			return true 
			
	return false
