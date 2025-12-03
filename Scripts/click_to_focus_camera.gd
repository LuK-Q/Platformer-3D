extends Node3D

@onready var camera = get_node("../../CameraPivot/Camera3D")
@onready var director = get_parent()

var focus_point: Node3D

var DEFAULT_FOLLOW_SPEED: float = 5.0
var DEFAULT_ROTATION_SPEED: float = 5.0

const FOCUS_FOLLOW_SPEED := 2.0
const FOCUS_ROTATION_SPEED := 1.5


func _ready():

	focus_point = Node3D.new()
	add_child(focus_point)
	DEFAULT_FOLLOW_SPEED = camera.follow_speed
	DEFAULT_ROTATION_SPEED = camera.rotation_speed


func _physics_process(_delta: float) -> void:
	var viewport := get_viewport()
	
	# RIGHT CLICK
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		var mouse_pos := viewport.get_mouse_position()
		var from: Vector3 = camera.project_ray_origin(mouse_pos)
		var to: Vector3 = from + camera.project_ray_normal(mouse_pos) * 100.0
		var query := PhysicsRayQueryParameters3D.create(from, to)
		var result := get_world_3d().direct_space_state.intersect_ray(query)

		if result:
			focus_point.global_position = result.position
			director.focus_on(
				focus_point,
				Vector3(0, 20, 16),
				1.5,
				FOCUS_FOLLOW_SPEED,
				FOCUS_ROTATION_SPEED
			)

	# LEFT CLICK
	#else:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		director.reset_to_default()
		camera.follow_speed = DEFAULT_FOLLOW_SPEED
		camera.rotation_speed = DEFAULT_ROTATION_SPEED
