extends State

var vault_timer: float = 0.0
var vault_direction: Vector3
var vault_speed: float = 6.0

func enter() -> void:
	player.anim_tree.set("parameters/conditions/is_vaulting", true)
	player.state_machine_playback.start("Vaulting")
	#player.upper_collision.set_deferred("disabled", true)
	player.lower_collision.set_deferred("disabled", true)
	vault_timer = 0.6 
	vault_direction = player.pivot.global_transform.basis.z
	player.velocity.y = player.jump_velocity * 0.8
	vault_speed = player.run_speed * 0.8

func physics_update(delta: float) -> void:
	vault_timer -= delta
	player.velocity.x = vault_direction.x * vault_speed
	player.velocity.z = vault_direction.z * vault_speed
	player.velocity.y -= player.get_gravity_value() * delta
	player.move_and_slide()
	
	if vault_timer <= 0.0:
		state_machine.transition_to("Airborne")

func exit() -> void:
	#player.upper_collision.set_deferred("disabled", true)
	player.lower_collision.set_deferred("disabled", false)
	player.anim_tree.set("parameters/conditions/is_vaulting", false)
	
	var airborne = state_machine.get_node("Airborne")
	if airborne: airborne.vault_cooldown = 0.5
	
	var grounded = state_machine.get_node("Grounded")
	if grounded: grounded.vault_cooldown = 0.5
