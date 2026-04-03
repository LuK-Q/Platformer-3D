extends State

var run_timer: float = 0.0
var wall_normal: Vector3

func enter() -> void:
	player.HighWallRay.force_raycast_update()
	if player.HighWallRay.is_colliding():
		wall_normal = player.HighWallRay.get_collision_normal()
	run_timer = 1.0 
	player.velocity.y = player.jump_velocity * 1.2
	player.anim_tree.set("parameters/conditions/wall_run_up", true)
	player.state_machine_playback.start("Wall Run Forward")

func physics_update(delta: float) -> void:
	run_timer -= delta
	if Input.is_action_just_pressed("jump"):
		perform_exit_leap(true)
		return

	player.HighWallRay.force_raycast_update()
	
	if not player.HighWallRay.is_colliding():
		var airborne = state_machine.get_node("Airborne")
		if airborne and airborne.check_ledge_grab_opportunity(true):
			return

		perform_exit_leap(false)
		return

	if run_timer <= 0:
		perform_exit_leap(false) 
		return
		
	if not Input.is_action_pressed("move_forward"):
		perform_exit_leap(false)
		return

	var push_to_wall = -wall_normal * 2.0
	player.velocity.x = push_to_wall.x
	player.velocity.z = push_to_wall.z
	player.velocity.y -= (player.get_gravity_value() * 0.6) * delta
	player.move_and_slide()

# Funkcja wyrzucająca postać poza zasięg Raycasta
func perform_exit_leap(is_jump: bool) -> void:
	var exit_velocity: Vector3
	
	if is_jump:
		exit_velocity = (wall_normal * 1.5 + Vector3.UP * 1.2).normalized() * player.jump_velocity
		player.state_machine_playback.travel("Running Jump")
	else:
		exit_velocity = (wall_normal * 0.5 + Vector3.UP * 0.2).normalized() * (player.jump_velocity * 0.5)
		player.state_machine_playback.travel("Falling")
	
	player.velocity = exit_velocity
	state_machine.transition_to("Airborne")

func exit() -> void:
	player.anim_tree.set("parameters/conditions/wall_run_up", false)
	
	var airborne = state_machine.get_node("Airborne")
	if airborne:
		airborne.vertical_wall_run_cooldown = 0.5
		airborne.vault_cooldown = 0.4
	
