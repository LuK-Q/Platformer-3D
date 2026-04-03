extends State

var ledge_y: float = 0.0

var vertical_duration: float = 0.6
var vertical_distance: float = 1.1

var forward_duration: float = 0.4
var forward_distance: float = 0.8

var current_phase: int = 0
var timer: float = 0.0
var start_pos: Vector3

func enter() -> void:
	player.velocity = Vector3.ZERO
	player.anim_tree.set("parameters/conditions/is_climbing", true)
	player.state_machine_playback.travel("LedgeClimb")
	player.lower_collision.set_deferred("disabled", true)
	if "upper_collision" in player:
		player.upper_collision.set_deferred("disabled", true)
	current_phase = 0
	timer = 0.0
	start_pos = player.global_position

func physics_update(delta: float) -> void:
	timer += delta
	
	if current_phase == 0:
		var t = clamp(timer / vertical_duration, 0.0, 1.0)
		var target_y = start_pos.y + vertical_distance
		player.global_position.y = lerp(start_pos.y, target_y, t)
		
		if timer >= vertical_duration:
			current_phase = 1
			timer = 0.0
			start_pos = player.global_position
			
	elif current_phase == 1:
		var t = clamp(timer / forward_duration, 0.0, 1.0)
		var forward_dir = player.pivot.global_transform.basis.z
		var target_pos = start_pos + (forward_dir * forward_distance)
		
		player.global_position = start_pos.lerp(target_pos, t)
		
		if timer >= forward_duration:
			player.global_position.y = ledge_y 
			state_machine.transition_to("Grounded")

func exit() -> void:
	player.anim_tree.set("parameters/conditions/is_climbing", false)
	player.lower_collision.set_deferred("disabled", false)
	if "upper_collision" in player:
		player.upper_collision.set_deferred("disabled", false)
