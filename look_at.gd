extends Camera3D

@export var target: CharacterBody3D       # The player or object to look at
@export var rotation_speed: float = 4.0   # How fast the camera rotates
@export var vertical_offset: float = 2.0  # Look slightly above the target

func _physics_process(delta):
	if target == null:
		return

	# Smoothly rotate the camera to look at the target
	_look_at_target_interpolated(delta * rotation_speed)

func _look_at_target_interpolated(weight: float) -> void:
	# Copy the current transform
	var xform := transform

	# Compute the look-at transform (with a vertical offset)
	var target_pos := target.global_position + Vector3.UP * vertical_offset
	xform = xform.looking_at(target_pos, Vector3.UP)

	# Interpolate between current transform and desired transform
	transform = transform.interpolate_with(xform, weight)




#extends Camera3D
#
#@export var target: CharacterBody3D
#@export var offset: Vector3 = Vector3(0, 15, 12) # isometric angle
#@export var follow_speed: float = 3.0           # smaller = more lag
#
#func _physics_process(delta):
	#if target == null:
		#return
#
	## World-space desired position (true isometric)
	#var desired_position = target.global_position + offset
#
	## Move camera slightly slower than the player
	#global_position = global_position.lerp(desired_position, follow_speed * delta)
#
	## Always look at the player
	#look_at(target.global_position, Vector3.UP)
	
	
	
	
	
#extends Camera3D
#
#@export var target: CharacterBody3D
#@export var offset: Vector3 = Vector3(0, 15, 12) # Base isometric position
#@export var follow_speed: float = 5.0           # Camera lag smoothing
#@export var rotation_speed: float = 2.0         # How fast camera rotates to follow movement
#@export var max_angle_offset: float = 20.0      # Max angle (degrees) the camera can tilt horizontally
#
#var current_offset: Vector3
#
#func _ready():
	#if target:
		#current_offset = offset
#
#func _physics_process(delta):
	#if target == null:
		#return
#
	## Player movement direction
	#var move_dir = target.velocity
	#move_dir.y = 0
#
	## Dynamic horizontal offset based on movement direction
	#if move_dir.length() > 0.1:
		#var angle = atan2(move_dir.x, move_dir.z) # Movement angle
		#var angle_offset = deg_to_rad(clamp(rad_to_deg(angle) * 0.5, -max_angle_offset, max_angle_offset))
		#var rotated_offset = offset.rotated(Vector3.UP, angle_offset)
		#current_offset = current_offset.lerp(rotated_offset, rotation_speed * delta)
	#else:
		## Return to default when idle
		#current_offset = current_offset.lerp(offset, rotation_speed * delta)
#
	## Desired camera position
	#var desired_position = target.global_position + current_offset
#
	## Smooth follow
	#global_position = global_position.lerp(desired_position, follow_speed * delta)
#
	## Always look at the player
	#look_at(target.global_position, Vector3.UP)
