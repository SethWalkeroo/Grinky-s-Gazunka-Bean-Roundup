extends Node3D

@onready var audio_player: AudioStreamPlayer3D = $AudioStreamPlayer3D
@onready var decal: Decal = get_node_or_null("Decal") 
# Make sure this matches the exact name of your particle node!
@onready var particles: GPUParticles3D = get_node_or_null("GPUParticles3D") 

var appropriate_decal

# Load your sounds using UIDs
const DEFAULT_IMPACT_SOUND = preload("uid://bj5eufoducvmq")
const METAL_IMPACT_SOUND = preload("uid://cpf27n6tf637h")
const WOOD_IMPACT_SOUND = preload("uid://u31q41hrhwul")
const FLESH_IMPACT_SOUND = preload("uid://de0sftvqqjsi4")

func play_impact(surface_type: String) -> void:
	# Choose the right sound
	match surface_type:
		"wood":
			audio_player.stream = WOOD_IMPACT_SOUND
		"metal":
			audio_player.stream = METAL_IMPACT_SOUND
		"flesh":
			audio_player.stream = FLESH_IMPACT_SOUND
		_:
			audio_player.stream = DEFAULT_IMPACT_SOUND
			
	# --- MEATY SOUND FIX ---
	# Add a microscopic delay (0 to 30ms) so 8 pellets sound like a 
	# heavy impact rather than a single weird beep/pop.
	var micro_delay = randf_range(0.01, 0.03)
	await get_tree().create_timer(micro_delay).timeout
	
	if is_instance_valid(audio_player):
		# Wider pitch range makes the impact sound "thicker"
		audio_player.pitch_scale = randf_range(0.7, 1.3)
		audio_player.play()

func _ready() -> void:
	# 1. Wait a short time for the particles to do their burst (e.g., 1 second)
	await get_tree().create_timer(1.0).timeout
	
	# Safely delete JUST the particles so they are completely gone
	if is_instance_valid(particles):
		particles.queue_free()
	
	# 2. Wait the remaining time (3 seconds) so the bullet hole stays solid for a total of 4 seconds
	await get_tree().create_timer(3.0).timeout
	
	# 3. Create a Tween to handle the smooth fade of the bullet hole
	var tween = get_tree().create_tween()
	
	if is_instance_valid(decal):
		# Tell the tween to smoothly drop the decal's opacity to 0.0 over 2.0 seconds
		tween.tween_property(decal, "albedo_mix", 0.0, 2.0)
		await tween.finished
		
	# 4. Now that the decal is invisible, safely delete the rest of the node
	queue_free()
