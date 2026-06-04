extends RigidBody3D

@onready var thud_sound: AudioStreamPlayer3D = $thud_sound
@onready var heart_light: OmniLight3D = $heart_light

# --- PULSING LIGHT SETTINGS ---
@export var pulse_speed: float = 3.0       # Higher = faster heartbeat tempo
@export var pulse_amplitude: float = 0.25   # Higher = more extreme brightness change

var base_light_energy: float = 1.0
var pulse_time: float = 0.0

# Stores the velocity from the frame right BEFORE the impact
var last_frame_velocity: Vector3 = Vector3.ZERO

func _ready() -> void:
	# Capture the starting energy set in the Godot inspector
	if heart_light:
		base_light_energy = heart_light.light_energy
		
	# 1. FORCE ON COLLISION MONITORING (Saves you from messing with the Inspector)
	contact_monitor = true
	max_contacts_reported = 3
	
	# 2. AUTOMATICALLY CONNECT SIGNAL
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	# Constantly cache how fast the ball is traveling before it hits a wall/floor
	last_frame_velocity = linear_velocity
	
	# --- LIGHT PULSE LOGIC ---
	if heart_light:
		pulse_time += delta * 2.500
		# sin() fluctuates smoothly between -1.0 and 1.0 over time
		var pulse_offset = sin(pulse_time * pulse_speed) * pulse_amplitude
		heart_light.light_energy = base_light_energy + pulse_offset

func _on_body_entered(body: Node) -> void:
	if not thud_sound.playing:
		# Use last_frame_velocity because current linear_velocity is already altered
		if last_frame_velocity.length() > 2.0:
			thud_sound.pitch_scale = randf_range(0.8, 1.2) 
			thud_sound.play()
