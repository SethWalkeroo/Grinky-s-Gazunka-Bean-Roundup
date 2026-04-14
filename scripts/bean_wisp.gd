extends Node3D

var path: PackedVector3Array = []
var current_path_index: int = 0
var speed: float = 12.0 
var lifetime: float = 4.0 

var base_volume: float = 0.0 
var time_alive: float = 0.0 # <-- NEW: A timer specifically for our sine wave!

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var pixie_dust: GPUParticles3D = $PixieDust 
@onready var chimes_audio: AudioStreamPlayer3D = $AudioStreamPlayer3D 

func _ready() -> void:
	# Add a cool pop-in animation when it spawns!
	scale = Vector3.ZERO
	var tween = get_tree().create_tween()
	tween.tween_property(self, "scale", Vector3.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Memorize the volume
	if chimes_audio:
		base_volume = chimes_audio.volume_db

func _process(delta: float) -> void:
	# Tick down the death timer, tick up the alive timer
	lifetime -= delta
	time_alive += delta 
	
	# --- THE ORGANIC BOB ---
	# sin() creates a wave. We multiply the time by 8.0 for the speed of the flap,
	# and multiply the final result by 0.15 so it only moves 15cm up and down.
	var bob_offset = sin(time_alive * 8.0) * 0.15
	
	if mesh:
		mesh.position.y = bob_offset
	if pixie_dust:
		pixie_dust.position.y = bob_offset
	# -----------------------

	if lifetime <= 1.0:
		if mesh:
			mesh.transparency = 1.0 - lifetime # Smooth fade out
		if pixie_dust:
			pixie_dust.emitting = false # Stop dropping dust
			
		if chimes_audio:
			chimes_audio.volume_db = base_volume + linear_to_db(max(lifetime, 0.001))
			
	if lifetime <= 0.0:
		queue_free()
		return
		
	# Follow the breadcrumb trail!
	if current_path_index < path.size():
		var target_pos = path[current_path_index]
		
		# Move smoothly toward the next point
		global_position = global_position.move_toward(target_pos, speed * delta)
		
		# If we get close to the point, target the next one
		if global_position.distance_squared_to(target_pos) < 0.1:
			current_path_index += 1
