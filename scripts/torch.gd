extends RigidBody3D
class_name Torch

@onready var collision_noise: AudioStreamPlayer3D = $collision_noise
@onready var raycast: RayCast3D = $RayCast3D

@onready var light: OmniLight3D = $torchlight
@onready var sparks: GPUParticles3D = $sparks
@onready var fire: GPUParticles3D = $fire
@onready var light_anim: AnimationPlayer = $light_animation # <-- Grab the animation player

@export var wall_torch = false
var default_energy: float = 1


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	default_energy = light.light_energy 
	
	# Prevent the raycast from hitting the torch's own collision body!
	raycast.add_exception(self)


func _physics_process(delta: float) -> void:
	if raycast.is_colliding():
		# The raycast hit a ceiling! Stop the flicker animation from fighting us.
		if light_anim.is_playing():
			light_anim.stop()
			
		# Smoothly dim the light to 0.0 (Pitch black)
		light.light_energy = lerp(light.light_energy, 0.0, delta * 8.0)
	else:
		# The space above is clear! Smoothly brighten the light back to normal.
		light.light_energy = lerp(light.light_energy, default_energy, delta * 8.0)
		
		# Once the light is mostly bright again, turn the fire flicker back on!
		# IMPORTANT: Change "flicker" to whatever your animation is actually named!
		if not light_anim.is_playing() and light.light_energy > (default_energy * 0.8):
			light_anim.play("init") 


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
