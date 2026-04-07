extends OmniLight3D

@export var base_energy: float = 0.8  # Lowered default energy
@export var min_range: float = 4.5    # Tightened radius
@export var max_range: float = 6.0    # Maximum reach
@export var flicker_speed: float = 0.08 # How often it jumps (seconds)

var target_energy: float = 0.8
var target_range: float = 5.0

func _ready():
	# Update the target values randomly on a loop
	_update_flicker()

func _update_flicker():
	# Pick a new random target for the light to move toward
	target_energy = randf_range(0.6, 1.1)
	target_range = randf_range(min_range, max_range)
	
	# Wait for a random short burst of time
	await get_tree().create_timer(randf_range(0.05, 0.15)).timeout
	_update_flicker()

func _process(delta: float):
	# Smoothly slide (Lerp) toward the targets so it's not "strobey"
	light_energy = lerp(light_energy, target_energy, 10.0 * delta)
	omni_range = lerp(omni_range, target_range, 10.0 * delta)
