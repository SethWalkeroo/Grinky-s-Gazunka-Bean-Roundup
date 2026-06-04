extends Node3D

@onready var table_light: OmniLight3D = $table_light

# Trackers for smooth transition and pulsing states
var player_is_hidden: bool = false
var pulse_time: float = 0.0
var transition_weight: float = 0.0 # Blends from 0.0 (unhidden) to 1.0 (hidden)

# Store original inspector values
var default_color: Color
var default_energy: float
var default_range: float

# Define the brighter hidden indicator values
var target_color: Color
var target_energy: float

func _ready() -> void:
	if table_light:
		# 1. Capture your default green and baseline settings from the inspector
		default_color = table_light.light_color
		default_energy = table_light.light_energy
		default_range = table_light.omni_range
		
		# 2. Setup the target lighter green shade and higher base intensity
		target_color = default_color.lightened(0.25) # Shifts to a lighter/more vibrant green
		target_energy = default_energy * 1.35       # 35% brighter base when hidden

func _process(delta: float) -> void:
	if not table_light: return
	
	# Smoothly advance or retreat the transition progress over time
	if player_is_hidden:
		transition_weight = move_toward(transition_weight, 1.0, delta * 4.0) # 0.25 seconds to blend in
		pulse_time += delta * 3.5 # Speed of the blinking/pulse
	else:
		transition_weight = move_toward(transition_weight, 0.0, delta * 4.0) # 0.25 seconds to blend out
		pulse_time = 0.0 # Reset pulse timing when completely out
		
	# 3. Calculate the baseline transition values based on our progress weight
	var current_base_color = default_color.lerp(target_color, transition_weight)
	var current_base_energy = lerp(default_energy, target_energy, transition_weight)
	
	# 4. Generate the continuous dynamic pulse wave
	var wave = sin(pulse_time)
	
	# Grows and shrinks the light radius slightly (+/- 6% max), scaled by transition progress
	table_light.omni_range = default_range * (1.0 + (wave * 0.06 * transition_weight))
	
	# Blinks/throbs the light brightness slightly (+/- 5% max), scaled by transition progress
	table_light.light_energy = current_base_energy * (1.0 + (wave * 0.05 * transition_weight))
	
	# Update the final color blend
	table_light.light_color = current_base_color

func _on_hiding_area_body_entered(body: Node3D) -> void:
	if body is Player:
		body.is_hidden = true
		player_is_hidden = true
		
		for voiceline in body.bean_pickup_voicelines.get_children():
			voiceline.stop()
		body.shh.play()

func _on_hiding_area_body_exited(body: Node3D) -> void:
	if body is Player:
		body.is_hidden = false
		player_is_hidden = false
