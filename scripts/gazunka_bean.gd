extends RigidBody3D

@export var rotation_speed: float = 2.0
@export var float_amplitude: float = 0.2  # How high it bobs
@export var float_frequency: float = 2.0  # How fast it bobs

var initial_y: float
var time_passed: float = 0.0

func _ready():
	# Store the starting height
	initial_y = global_position.y
	
	# Optional: If you want it to hover without falling, 
	# set freeze mode to enabled so gravity doesn't pull it down
	freeze = true 

func _physics_process(delta):
	time_passed += delta
	
	# 1. Constant Rotation
	rotate_y(rotation_speed * delta)
	
	# 2. Vertical Sine Wave (Levitation)
	# Formula: y = initial_y + sin(time * frequency) * amplitude
	var new_y = initial_y + (sin(time_passed * float_frequency) * float_amplitude)
	global_position.y = new_y
