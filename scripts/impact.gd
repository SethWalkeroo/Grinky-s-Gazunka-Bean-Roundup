extends Node3D

@onready var audio_player: AudioStreamPlayer3D = $AudioStreamPlayer3D
@onready var decal: Decal = get_node_or_null("Decal") 
@onready var particles: GPUParticles3D = get_node_or_null("GPUParticles3D") 
@onready var flesh_decal: Decal = $FleshDecal
@onready var impact_particles: GPUParticles3D = $GPUParticles3D
@onready var wood_decal: Decal = $WoodDecal

var appropriate_decal = decal

# Load your sounds using UIDs
const DEFAULT_IMPACT_SOUND = preload("uid://bj5eufoducvmq")
const METAL_IMPACT_SOUND = preload("uid://cpf27n6tf637h")
const WOOD_IMPACT_SOUND = preload("uid://dap2as4n85r1c")
const FLESH_IMPACT_SOUND = preload("uid://de0sftvqqjsi4")

func play_impact(surface_type: String) -> void:
	# Hide both decals immediately so they don't overlap
	if is_instance_valid(decal):
		decal.visible = false
	if is_instance_valid(flesh_decal):
		flesh_decal.visible = false
	if is_instance_valid(wood_decal):
		wood_decal.visible = false
		
	# --- NEW: PARTICLE COLOR LOGIC ---
	if is_instance_valid(particles) and particles.process_material:
		# Duplicate the material so we don't accidentally turn ALL bullet holes red!
		var p_mat = particles.process_material.duplicate() as ParticleProcessMaterial
		particles.process_material = p_mat
		
		# Set the color based on the surface
		match surface_type:
			"wood":
				p_mat.color = Color(0.4, 0.2, 0.05) # Splinter Brown
			"metal":
				p_mat.color = Color(1.0, 0.9, 0.3) # Spark Yellow/Orange
			"flesh":
				p_mat.color = Color(0.6, 0.0, 0.0) # Dark Blood Red
			_:
				p_mat.color = Color(0.5, 0.5, 0.5) # Concrete Dust Gray
				
		# Force the particles to emit instantly!
		particles.emitting = true
		
	# Choose the right sound AND turn the correct decal back on
	match surface_type:
		"wood":
			appropriate_decal = wood_decal
			if is_instance_valid(decal): wood_decal.visible = true
			audio_player.stream = WOOD_IMPACT_SOUND
		"metal":
			appropriate_decal = decal
			if is_instance_valid(decal): decal.visible = true
			audio_player.stream = METAL_IMPACT_SOUND
		"flesh":
			appropriate_decal = flesh_decal
			if is_instance_valid(flesh_decal): flesh_decal.visible = true
			audio_player.stream = FLESH_IMPACT_SOUND
		_:
			appropriate_decal = decal
			if is_instance_valid(decal): decal.visible = true
			audio_player.stream = DEFAULT_IMPACT_SOUND
			
	# --- MEATY SOUND FIX ---
	var micro_delay = randf_range(0.01, 0.03)
	await get_tree().create_timer(micro_delay).timeout
	
	if is_instance_valid(audio_player):
		audio_player.pitch_scale = randf_range(0.7, 1.3)
		audio_player.play()

func _ready() -> void:
	# 1. Wait a short time for the particles to do their burst (e.g., 1 second)
	await get_tree().create_timer(1.5).timeout
	
	# Safely delete JUST the particles so they are completely gone
	if is_instance_valid(particles):
		particles.queue_free()
	
	# 2. Wait the remaining time (3 seconds) so the bullet hole stays solid for a total of 4 seconds
	await get_tree().create_timer(3.0).timeout
	
	# 3. Create a Tween to handle the smooth fade of the bullet hole
	var tween = get_tree().create_tween()
	
	if is_instance_valid(appropriate_decal):
		# Tell the tween to smoothly drop the decal's opacity to 0.0 over 2.0 seconds
		tween.tween_property(appropriate_decal, "albedo_mix", 0.0, 2.0)
		await tween.finished
		
	# 4. Now that the decal is invisible, safely delete the rest of the node
	queue_free()
