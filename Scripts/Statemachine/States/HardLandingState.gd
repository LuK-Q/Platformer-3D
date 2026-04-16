extends State

var stun_timer: float = 0.0

func enter() -> void:
	player.velocity.x = 0.0
	player.velocity.z = 0.0
	stun_timer = 1.8 
	player.anim_tree.set("parameters/conditions/is_hard_landing", true)
	player.state_machine_playback.travel("hard landing")
	# Tutaj camera shake
	# lub  dźwięk uderzenia

func physics_update(delta: float) -> void:
	stun_timer -= delta
	if not player.is_on_floor():
		player.velocity.y -= player.get_gravity_value() * delta
	player.move_and_slide()
	if stun_timer <= 0.0:
		state_machine.transition_to("Grounded")

func exit() -> void:
	player.anim_tree.set("parameters/conditions/is_hard_landing", false)
