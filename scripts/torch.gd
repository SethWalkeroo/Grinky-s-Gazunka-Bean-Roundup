extends RigidBody3D
class_name Torch

@onready var collision_noise: AudioStreamPlayer3D = $collision_noise

@onready var light: OmniLight3D = $torchlight
@onready var sparks: GPUParticles3D = $sparks
@onready var fire: GPUParticles3D = $fire
@export var wall_torch = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.



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
