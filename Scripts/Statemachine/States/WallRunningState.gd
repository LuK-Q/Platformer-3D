extends State

var wall_normal: Vector3
var run_direction: Vector3
var run_timer: float = 0.0
var side: int = 0 

func enter() -> void:
	player.WallRayLeft.force_raycast_update()
	player.WallRayRight.force_raycast_update()
	
	if player.WallRayLeft.is_colliding():
		side = -1
		wall_normal = player.WallRayLeft.get_collision_normal()
		player.anim_tree.set("parameters/conditions/wall_run_left", true)
		player.state_machine_playback.start("Wall Run LEFT") 
	else:
		side = 1
		wall_normal = player.WallRayRight.get_collision_normal()
		player.anim_tree.set("parameters/conditions/wall_run_right", true)
		player.state_machine_playback.start("Wall Run RIGHT")
		
	#Obliczanie kierunku biegu
	var forward = Vector3.UP.cross(wall_normal).normalized()
	if forward.dot(player.pivot.global_transform.basis.z) < 0:
		forward = -forward
	run_direction = forward
	
	player.velocity.y = player.jump_velocity * 0.6 
	run_timer = player.wall_run_max_time 

func physics_update(delta: float) -> void:
	run_timer -= delta
	
	if player.is_on_floor():
		state_machine.transition_to("Grounded")
		return

	if run_timer <= 0:
		perform_wall_jump(true)
		return

	if Input.is_action_just_pressed("jump"):
		perform_wall_jump(false)
		return

	var current_ray = player.WallRayLeft if side == -1 else player.WallRayRight
	current_ray.force_raycast_update()
	if not current_ray.is_colliding():
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

# odskok i zmiana animacji
func perform_wall_jump(is_auto: bool) -> void:
	var forward_power = 2.5 
	var away_power = 1.2   
	var up_power = 3       
	
	if is_auto:
		forward_power *= 0.8
		up_power *= 0.8

	var jump_dir = (run_direction * forward_power + wall_normal * away_power + Vector3.UP * up_power).normalized()

	player.velocity = jump_dir * (player.jump_velocity * 1.5)
	
	var airborne = state_machine.get_node("Airborne")
	if airborne:
		airborne.wall_run_cooldown = 0.3 
	
	player.state_machine_playback.travel("Running Jump")
	state_machine.transition_to("Airborne")
	
func exit() -> void:
	player.anim_tree.set("parameters/conditions/wall_run_left", false)
	player.anim_tree.set("parameters/conditions/wall_run_right", false)
	var airborne = state_machine.get_node("Airborne")
	if airborne:
		airborne.wall_run_cooldown = 0.3
		airborne.vault_cooldown = 0.4
