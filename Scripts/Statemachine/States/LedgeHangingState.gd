extends State

var wall_normal: Vector3 = Vector3.ZERO
var ledge_height: float = 0.0

var hanging_y_offset: float = 1.45
var shimmy_speed: float = 2.0
var ledge_y: float = 0.0

var jump_180_rotation_delay: float = 0.6  # Czas od wciśnięcia skoku do STARTU obrotu
var jump_180_rotation_time: float = 0.2   # Ile sekund trwa sam płynny obrót
var jump_180_physics_delay: float = 0.85  # Kiedy postać fizycznie leci w tył (musi być > rotation_delay)

var jump_180_up_force: float = 7.5
var jump_180_back_force: float = 6.0

var is_jumping_180: bool = false
var jump_timer: float = 0.0
var start_rotation: float = 0.0
var target_rotation: float = 0.0
var start_pos = 0.0

func enter() -> void:
	is_jumping_180 = false
	jump_timer = 0.0
	
	player.velocity = Vector3.ZERO
	player.anim_tree.set("parameters/conditions/is_hanging", true)
	player.state_machine_playback.travel("LedgeHang")
	player.anim_tree.set("parameters/LedgeHang/blend_position", 0.0)
	
	target_rotation = atan2(-wall_normal.x, -wall_normal.z)
	
	player.pivot.rotation.y = target_rotation
	player.global_position.y = ledge_height - hanging_y_offset

func physics_update(delta: float) -> void:
	if is_jumping_180:
		start_pos = player.global_position
		jump_timer += delta
		player.global_position.y = lerp(start_pos.y, (start_pos.y+0.09), 0.3)
		if jump_timer >= jump_180_rotation_delay and jump_timer < (jump_180_rotation_delay + jump_180_rotation_time):
			var t = (jump_timer - jump_180_rotation_delay) / jump_180_rotation_time
			player.pivot.rotation.y = lerp_angle(start_rotation, target_rotation, t)
			
		elif jump_timer >= (jump_180_rotation_delay + jump_180_rotation_time):
			player.pivot.rotation.y = target_rotation
			
		if jump_timer >= jump_180_physics_delay:
			perform_final_jump()
		return

	if Input.is_action_just_pressed("crouch"):
		var airborne = state_machine.get_node("Airborne")
		if airborne:
			airborne.ledge_grab_cooldown = 0.5
		player.state_machine_playback.travel("LedgeDrop")
		state_machine.transition_to("Airborne")
		return
		
	if Input.is_action_just_pressed("jump") and Input.is_action_pressed("move_back"):
		is_jumping_180 = true
		jump_timer = 0.0
		
		start_rotation = player.pivot.rotation.y
		target_rotation = atan2(wall_normal.x, wall_normal.z)
		
		player.state_machine_playback.travel("LedgeJump180")
		return
		
	if Input.is_action_just_pressed("jump") and Input.is_action_pressed("move_forward"):
		if can_climb_to_ledge():
			var climb_state = state_machine.get_node("LedgeClimbing")
			if climb_state:
				climb_state.ledge_y = ledge_height
			state_machine.transition_to("LedgeClimbing")
		else:
			print("Nie można się wspiąć - przeszkoda nad krawędzią")
		return

	handle_shimmy_movement(delta)

func perform_final_jump() -> void:
	player.velocity = Vector3.UP * jump_180_up_force
	player.velocity += wall_normal * jump_180_back_force
	state_machine.transition_to("Airborne")

func handle_shimmy_movement(delta: float) -> void:
	var input_x = Input.get_axis("move_left", "move_right")
	var right_direction = Vector3.UP.cross(wall_normal).normalized()
	
	if input_x != 0:
		var shimmy_dir = right_direction * sign(input_x)
		if not check_ledge_continuity(shimmy_dir):
			input_x = 0.0
	
	var shimmy_velocity = right_direction * input_x * shimmy_speed

	player.velocity.x = shimmy_velocity.x
	player.velocity.z = shimmy_velocity.z
	player.velocity.y = 0
	player.move_and_slide()

	var current_blend = player.anim_tree.get("parameters/LedgeHang/blend_position")
	var new_blend = lerp(current_blend, float(input_x), 10.0 * delta)
	player.anim_tree.set("parameters/LedgeHang/blend_position", new_blend)

func check_ledge_continuity(direction: Vector3) -> bool:
	var chest_cast = player.get_node("Pivot/LedgeChestCast")
	var height_node = player.get_node("Pivot/LedgeHeightNode")
	var height_ray = height_node.get_node("LedgeHeightRay")
	var orig_chest_pos = chest_cast.global_position
	var orig_height_pos = height_node.global_position
	var look_ahead_distance = 0.4
	chest_cast.global_position += direction * look_ahead_distance
	chest_cast.force_shapecast_update()
	var is_ledge_valid = false
	
	if chest_cast.is_colliding():
		var new_hit_point = chest_cast.get_collision_point(0)
		var new_normal = chest_cast.get_collision_normal(0)

		var in_wall_vec = -new_normal * 0.15
		height_node.global_position = Vector3(new_hit_point.x + in_wall_vec.x, orig_height_pos.y, new_hit_point.z + in_wall_vec.z)
		height_ray.force_raycast_update()

		if height_ray.is_colliding():
			var new_ledge_y = height_ray.get_collision_point().y
			
			if abs(new_ledge_y - ledge_height) < 0.15:
				is_ledge_valid = true

	chest_cast.global_position = orig_chest_pos
	height_node.global_position = orig_height_pos
	
	return is_ledge_valid

func can_climb_to_ledge() -> bool:
	var space_cast = player.get_node_or_null("Pivot/ClimbSpaceCast")
	
	if space_cast:
		space_cast.force_shapecast_update()
		return not space_cast.is_colliding()
	
	push_warning("ClimbSpaceCast nie został znaleziony w Pivot!")
	return true

func exit() -> void:
	player.anim_tree.set("parameters/conditions/is_hanging", false)
