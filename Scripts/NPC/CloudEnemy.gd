extends CharacterBody3D

@export var chase_speed: float = 3.5 
var target: Node3D = null 

func _physics_process(_delta):
	if target:
		var space_state = get_world_3d().direct_space_state
		var start_pos = global_position + Vector3(0, 1.0, 0)
		var target_pos = target.global_position + Vector3(0, 1.0, 0)
		var query = PhysicsRayQueryParameters3D.create(start_pos, target_pos)
		
		query.exclude = [self]
		
		var result = space_state.intersect_ray(query)
		
		if result and result.collider.is_in_group("Player"):
			var direction = global_position.direction_to(target.global_position).normalized()
			velocity = direction * chase_speed
			
			if direction != Vector3.ZERO:
				look_at(global_position - direction, Vector3.UP)
		else:
			velocity = velocity.move_toward(Vector3.ZERO, chase_speed)
	else:
		velocity = velocity.move_toward(Vector3.ZERO, chase_speed)
	move_and_slide()


func _on_vision_area_body_entered(body):
	if body.is_in_group("Player"):
		target = body 

func _on_vision_area_body_exited(body):
	if body == target:
		target = null 

func _on_catch_area_body_entered(body):
	if body.is_in_group("Player"):
		ScreenFader.reload_scene(0.3)
