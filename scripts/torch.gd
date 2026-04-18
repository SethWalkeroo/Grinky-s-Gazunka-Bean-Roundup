extends RigidBody3D
class_name Torch

@onready var collision_noise: AudioStreamPlayer3D = $collision_noise
@onready var raycast: RayCast3D = $RayCast3D
@onready var extinguish_sound: AudioStreamPlayer3D = $extinguish

@onready var light: OmniLight3D = $torchlight
@onready var sparks: GPUParticles3D = $sparks
@onready var fire: GPUParticles3D = $fire
@onready var burning_sound: AudioStreamPlayer3D = $burning_sound

@export var wall_torch = false
var default_energy: float = 1

# --- BURN OUT VARIABLES ---
@export var max_burn_time: float = 30.0
var current_burn_time: float = 0.0
var has_been_grabbed: bool = false
var is_extinguished: bool = false

# --- PROCEDURAL FLICKER ---
var time_alive: float = 0.0

func _ready() -> void:
	default_energy = light.light_energy 
	current_burn_time = max_burn_time # Set the clock!
	
	# Prevent the raycast from hitting the torch's own collision body!
	raycast.add_exception(self)


func _physics_process(delta: float) -> void:	
	
	if is_extinguished: return
	
	time_alive += delta
		
	# --- 1. THE GRAB DETECTOR ---
	if not freeze and not has_been_grabbed:
		has_been_grabbed = true
		
	# --- 2. THE BURN CLOCK ---
	if has_been_grabbed:
		current_burn_time -= delta
		if current_burn_time <= 0.0:
			extinguish_torch()
			return # Stop processing this frame so the light doesn't turn back on
			
	# Dynamic Audio Control
	if light.light_energy <= 0.1 and burning_sound.playing:
		burning_sound.stop()
	elif light.light_energy > 0.1 and not burning_sound.playing:
		burning_sound.play()

	# --- 3. THE LIGHT & CEILING LOGIC ---
	if raycast.is_colliding():
		# Smoothly dim the light to 0.0 (Pitch black)
		light.light_energy = lerp(light.light_energy, 0.0, delta * 8.0)
		
		# --- GOAL 1: EXTINGUISH ON CRUSH ---
		# If it gets dark enough against the wall, kill it permanently!
		if light.light_energy <= 0.05:
			extinguish_torch()
			return
	else:
		# --- GOAL 2: AAA PROCEDURAL FLICKER ---
		# We combine 3 different sine waves running at different speeds to create a naturally breathing flame
		var organic_flicker = (sin(time_alive * 12.0) * 0.05) + (sin(time_alive * 25.0) * 0.03) + (sin(time_alive * 7.0) * 0.08)
		
		# Add a randomized "wind gust" micro-stutter (8% chance every frame)
		if randf() < 0.08:
			organic_flicker -= randf_range(0.1, 0.25)
			
		var target_energy = default_energy + organic_flicker
		
		# THE DYING FLICKER
		if has_been_grabbed and current_burn_time < 5.0:
			var dying_intensity = current_burn_time / 5.0
			target_energy = randf_range(0.3, 1.5) * dying_intensity
			
			# Make the lerp violently fast to simulate chaotic sputtering
			light.light_energy = lerp(light.light_energy, target_energy, delta * 25.0)
			
		# NORMAL LIGHT BEHAVIOR
		else:
			# Smoothly blend to the procedural target to keep the flame looking soft and gaseous
			light.light_energy = lerp(light.light_energy, target_energy, delta * 12.0)


func _on_timer_timeout() -> void:
	pass


func _on_body_entered(_body: Node) -> void:
	# Check if the sound is already playing so it doesn't overlap weirdly
	if not collision_noise.playing:
		# Optional: Only play if the impact is hard enough
		if linear_velocity.length() > 2.0:
			collision_noise.pitch_scale = randf_range(0.8, 1.2) 
			collision_noise.play()
			get_tree().call_group("enemy", "investigate_sound", global_position, 20.0)

# --- THE EXTINGUISH PROTOCOL ---
func extinguish_torch() -> void:
	print('extinguishing torch')
	is_extinguished = true
	if burning_sound:
		burning_sound.stop()
	if extinguish_sound:
		extinguish_sound.pitch_scale = randf_range(0.8, 1.2)
		extinguish_sound.play()
	
	if light: light.visible = false
	if fire: fire.emitting = false
	if sparks: sparks.emitting = false
