extends State

var roll_timer: float = 0.0
var roll_direction: Vector3

func enter() -> void:
	player.upper_collision.set_deferred("disabled", true)
	player.anim_tree.set("parameters/conditions/is_rolling", true)
	roll_timer = 0.8 
	
	var current_horizontal_velocity = Vector3(player.velocity.x, 0, player.velocity.z)
	
	if current_horizontal_velocity.length() > 1.0:
		roll_direction = current_horizontal_velocity.normalized()
	else:
		roll_direction = player.pivot.global_transform.basis.z 
		
	var roll_speed = player.run_speed * 1.3
	player.velocity.x = roll_direction.x * roll_speed
	player.velocity.z = roll_direction.z * roll_speed

func physics_update(delta: float) -> void:
	roll_timer -= delta
	player.velocity.x = move_toward(player.velocity.x, 0, player.friction * 0.05 * delta)
	player.velocity.z = move_toward(player.velocity.z, 0, player.friction * 0.05 * delta)
	
	if not player.is_on_floor():
		player.velocity.y -= player.get_gravity_value() * delta
		
	player.move_and_slide()

	if roll_timer <= 0:
		player.ceiling_ray.force_raycast_update()
		if Input.is_action_pressed("crouch") or player.is_ceiling_above():
			state_machine.transition_to("Crouching")
		else:
			state_machine.transition_to("Grounded")

func exit() -> void:
	player.upper_collision.set_deferred("disabled", false)
	player.anim_tree.set("parameters/conditions/is_rolling", false)
