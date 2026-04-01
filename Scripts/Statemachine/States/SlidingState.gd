extends State

var slide_timer: float = 0.0
var slide_direction: Vector3 = Vector3.ZERO
var is_leaving_ground: bool = false # Zabezpieczenie przed błędem animacji

func enter() -> void:
	player.upper_collision.set_deferred("disabled", true)
	player.anim_tree.set("parameters/conditions/is_sliding", true)
	player.anim_tree.set("parameters/conditions/is_not_sliding", false)
	is_leaving_ground = false # Resetujemy przy każdym wślizgu

	var current_horizontal_velocity = Vector3(player.velocity.x, 0, player.velocity.z)
	if current_horizontal_velocity.length() > 0:
		slide_direction = current_horizontal_velocity.normalized()
	else:
		slide_direction = player.pivot.global_transform.basis.z 
		
	var boost_speed = player.run_speed * player.slide_speed_multiplier
	player.velocity.x = slide_direction.x * boost_speed
	player.velocity.z = slide_direction.z * boost_speed
	slide_timer = player.slide_timer_max

func physics_update(delta: float) -> void:
	# 1. Zabezpieczenie: Spadek z krawędzi podczas wślizgu
	if not player.is_on_floor():
		is_leaving_ground = true # Zaznaczamy, że opuszczamy ziemię
		player.state_machine_playback.travel("Falling")
		state_machine.transition_to("Airborne")
		return
		
	# 2. Skok ze wślizgu
	if Input.is_action_just_pressed("jump"):
		player.ceiling_ray.force_raycast_update()
		if not player.is_ceiling_above():
			player.velocity.y = player.jump_velocity
			is_leaving_ground = true # Zaznaczamy, że opuszczamy ziemię
			
			# Bezpiecznie wywołujemy travel, bo exit() już go nie nadpisze!
			player.state_machine_playback.travel("Running Jump") 
			state_machine.transition_to("Airborne")
			return

	# 3. Zwalnianie (Friction)
	slide_timer -= delta
	player.velocity.x = move_toward(player.velocity.x, 0, player.slide_friction * delta)
	player.velocity.z = move_toward(player.velocity.z, 0, player.slide_friction * delta)
	
	var current_speed = Vector2(player.velocity.x, player.velocity.z).length()

	# 4. Koniec wślizgu
	if slide_timer <= 0 or current_speed < player.walk_speed:
		end_slide()
		return

	player.move_and_slide()

func end_slide() -> void:
	player.ceiling_ray.force_raycast_update()
	if player.is_ceiling_above() or Input.is_action_pressed("crouch"):
		state_machine.transition_to("Crouching")
	else:
		state_machine.transition_to("Grounded")

func exit() -> void:
	player.upper_collision.set_deferred("disabled", false)
	player.anim_tree.set("parameters/conditions/is_sliding", false)

	if not is_leaving_ground:
		player.anim_tree.set("parameters/conditions/is_not_sliding", true)
