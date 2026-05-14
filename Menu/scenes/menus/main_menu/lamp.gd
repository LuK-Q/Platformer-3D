extends Node3D

@onready var spotlight = $SpotLight3D

@export var base_swing_speed: float = 1.5
@export var speed_variance: float = 0.5 
@export var swing_angle: float = 5.0 

@export var flicker_chance: float = 0.007 
@export var recovery_speed: float = 2.0 
@export var fade_out_speed: float = 2.0 

var time_passed: float = 0.0
var swing_phase: float = 0.0 
var is_on: bool = true
var is_turning_off: bool = false
var base_energy: float = 0.0

func _ready():
	base_energy = spotlight.light_energy

func _process(delta):

	time_passed += delta
	var current_speed = base_swing_speed + sin(time_passed * 0.4) * speed_variance
	
	swing_phase += delta * current_speed * 0
	
	rotation_degrees.x = sin(swing_phase) * swing_angle
	rotation_degrees.z = sin(swing_phase) * swing_angle
	
	if is_turning_off:
		spotlight.light_energy = lerp(spotlight.light_energy, 0.0, delta * fade_out_speed)
	elif is_on:
		if randf() < flicker_chance:
			spotlight.light_energy = randf_range(0.0, base_energy * 0.8)
		else:
			spotlight.light_energy = lerp(spotlight.light_energy, base_energy, delta * recovery_speed)

func turn_off():
	is_on = false
	is_turning_off = true
