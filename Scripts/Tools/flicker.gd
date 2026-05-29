extends OmniLight3D

@export var base_energy: float = 1.2    
@export var flicker_strength: float = 0.5 
@export var flicker_speed: float = 5.0  

var time_passed: float = 0.0
var noise = FastNoiseLite.new()

func _ready():
	noise.seed = randi()
	noise.frequency = 0.5

func _process(delta):
	time_passed += delta * flicker_speed
	var n = noise.get_noise_1d(time_passed)

	light_energy = base_energy + (n * flicker_strength)
	if randf() < 0.001: 
		light_energy = 0.05
