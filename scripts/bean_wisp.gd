extends Node3D

var path: PackedVector3Array = []
var current_path_index: int = 0
var speed: float = 12.0 

# --- THE NEW LOGIC VARIABLES ---
var reached_destination: bool = false
var fade_timer: float = 5.0 

var base_volume: float = 0.0 
var base_light_energy: float = 0.0 
var time_alive: float = 0.0 

var orbit_center: Vector3
var orbit_angle: float = 0.0
var orbit_base_y: float = 0.0

# --- THE FIX: NEW SCALE VARIABLE ---
var base_mesh_scale: Vector3 

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var pixie_dust: GPUParticles3D = $PixieDust 
@onready var chimes_audio: AudioStreamPlayer3D = $chimes
@onready var wisp_light: OmniLight3D = $WispLight

func _ready() -> void:
	# Memorize the root scale for the pop-in animation
	var target_root_scale = scale
	
	# THE FIX: Memorize the exact scale of the mesh (your 0.15 xyz!)
	if mesh:
		base_mesh_scale = mesh.scale
		
	# Pop-in animation that respects your custom scale
	scale = Vector3.ZERO
	var tween = get_tree().create_tween()
	tween.tween_property(self, "scale", target_root_scale, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	if chimes_audio: base_volume = chimes_audio.volume_db
	if wisp_light: base_light_energy = wisp_light.light_energy

func _process(delta: float) -> void:
	time_alive += delta 
	
	# --- 1. NAVIGATION & GRAVITY CATCH ---
	if not reached_destination:
		if current_path_index < path.size():
			var target_pos = path[current_path_index]
			var is_last_point = (current_path_index == path.size() - 1)
			
			var arrival_dist = 0.5 if is_last_point else 0.1
			
			global_position = global_position.move_toward(target_pos, speed * delta)
			
			if global_position.distance_to(target_pos) < arrival_dist:
				if is_last_point:
					reached_destination = true
					orbit_center = target_pos
					orbit_base_y = global_position.y
					
					orbit_angle = atan2(global_position.z - orbit_center.z, global_position.x - orbit_center.x)
				else:
					current_path_index += 1
	
	# --- 2. ORBIT & ASCENSION ---
	var visual_fade_slider: float = 1.0
	
	if reached_destination:
		fade_timer -= delta
		visual_fade_slider = clamp(fade_timer - 2.0, 0.0, 1.0) 
		
		# Drive the orbit forward
		var orbit_speed = 6.0 
		orbit_angle += orbit_speed * delta
		
		# Shrink the radius as it fades
		var current_radius = 0.5 * visual_fade_slider
		
		# Move the actual root node in a circle
		global_position.x = orbit_center.x + cos(orbit_angle) * current_radius
		global_position.z = orbit_center.z + sin(orbit_angle) * current_radius
		
		# Lift the wisp 2.0 meters into the air over the 5 seconds!
		var upward_drift = (5.0 - fade_timer) * 0.4
		global_position.y = orbit_base_y + upward_drift

	# --- 3. THE ORGANIC BOB ---
	var bob_offset = sin(time_alive * 8.0) * 0.15
	if mesh: mesh.position.y = bob_offset
	if pixie_dust: pixie_dust.position.y = bob_offset
	if wisp_light: wisp_light.position.y = bob_offset 

	# --- 4. THE GHOST FADE SEQUENCE ---
	if reached_destination:
		if mesh:
			mesh.transparency = 1.0 - visual_fade_slider 
			# THE FIX: Now we multiply the slider against your actual starting size!
			mesh.scale = base_mesh_scale * visual_fade_slider
			
		if pixie_dust:
			if fade_timer <= 3.0:
				pixie_dust.emitting = false 
				
		if wisp_light:
			wisp_light.light_energy = base_light_energy * visual_fade_slider
			
		if chimes_audio:
			var audio_fade_progress = 1.0 - (max(fade_timer, 0.0) / 5.0)
			chimes_audio.volume_db = lerp(base_volume, -60.0, audio_fade_progress)

		if fade_timer <= 0.0:
			queue_free()
