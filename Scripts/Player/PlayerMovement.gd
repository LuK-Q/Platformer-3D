extends CharacterBody3D

# Ten skrypt teraz tylko przechowuje dane i referencje.
# Wszystkie obliczenia wykonują skrypty wewnątrz StateMachine.

#region EXPORTED VARIABLES
@export_group("Movement")
@export var walk_speed := 2.0
@export var run_speed := 5.0
@export var acceleration := 50.0 
@export var friction := 60.0    
@export var air_control := 0.1
@export var wall_run_arrival_v_limit: float = -2.0
@export var wall_run_max_time: float = 1.4

@export_group("Jump & Gravity")
@export var jump_velocity := 5.0
@export var gravity_multiplier := 2.0
@export var fall_gravity_multiplier := 3.0
@export var soft_land_threshold := -8.0 
@export var hard_land_threshold := -20.0 
@export var roll_threshold: float = -15.0

@export_group("Sliding & Crouching")
@export var slide_speed_multiplier := 1.6
@export var slide_friction := 5.0
@export var slide_timer_max := 1.2
@export var slide_activation_threshold := 5.0
#endregion

#region NODE REFERENCES
@onready var pivot: Node3D = $Pivot
@onready var camera_node: Camera3D = get_viewport().get_camera_3d()

@onready var ceiling_ray: RayCast3D = $Pivot/CeilingRay
@onready var HighWallRay: RayCast3D = $Pivot/HighWallRay
@onready var WallRayRight: RayCast3D = $Pivot/WallRayRight
@onready var WallRayLeft: RayCast3D = $Pivot/WallRayLeft
@onready var ledge_climb_cast: ShapeCast3D = $Pivot/ClimbSpaceCast

@onready var lower_collision: CollisionShape3D = $LowerCollision
@onready var upper_collision: CollisionShape3D = $UpperCollision

@onready var anim_tree: AnimationTree = $Pivot/playerModel/AnimationTree
@onready var state_machine_playback: AnimationNodeStateMachinePlayback = anim_tree.get("parameters/playback")
#endregion

func _ready() -> void:
	anim_tree.active = true
	if GameManager.has_checkpoint and GameManager.last_checkpoint_scene == get_tree().current_scene.scene_file_path:
		global_position = GameManager.last_checkpoint_position
		
# Funkcje pomocnicze
func get_gravity_value() -> float:
	return ProjectSettings.get_setting("physics/3d/default_gravity")

func is_ceiling_above() -> bool:
	ceiling_ray.force_raycast_update()
	return ceiling_ray.is_colliding()
