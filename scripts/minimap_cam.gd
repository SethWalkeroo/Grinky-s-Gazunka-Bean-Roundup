extends Camera3D

@export var pulse_interval: float = 2.5 # Seconds between sweeps
@export var fade_speed: float = 1.0     # How fast the UI fades to black

var pulse_timer: float = 0.0
var player: CharacterBody3D
var minimap_ui: TextureRect
var in_heaven: bool = false # Tracks which mode the minimap should be in

@onready var viewport: SubViewport = get_parent()
var texture_linked: bool = false

func _ready() -> void:
	# Force the camera to look straight down
	rotation_degrees.x = -90 
	player = get_tree().get_first_node_in_group('player')
	
	# --- SCENE CHECK ---
	# Look at the file path of the current level to see if we are in Heaven!
	if get_tree().current_scene.scene_file_path.ends_with("heaven.tscn"):
		in_heaven = true
		
		# Turn on the live 60fps video feed!
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player): return
	
	# Safely grab the minimap UI
	if not is_instance_valid(minimap_ui):
		minimap_ui = player.get_node_or_null("neck/head/eyes/CanvasLayer/circle_clip/minimap_rect")
		
	# Force the Viewport texture into the UI
	if is_instance_valid(minimap_ui) and not texture_linked:
		minimap_ui.texture = viewport.get_texture()
		texture_linked = true
		
	if in_heaven:
		# ==========================================
		# HEAVEN MODE: LIVE GPS TRACKING
		# ==========================================
		global_position = Vector3(
			player.global_position.x,
			100,
			player.global_position.z
		)
		
		# Keep North pointed UP so it's not disorienting
		rotation.y = 0.0 
		
		# Keep the screen fully bright, and turn off the glowing scanner ring
		if is_instance_valid(minimap_ui):
			minimap_ui.modulate.a = 1.0
			if minimap_ui.material:
				minimap_ui.material.set_shader_parameter("sweep_progress", 0.0)
				
	else:
		# ==========================================
		# DUNGEON MODE: ALIEN MOTION TRACKER
		# ==========================================
		pulse_timer -= delta
		if pulse_timer <= 0.0:
			trigger_pulse()
			
		if is_instance_valid(minimap_ui):
			# --- THE FIX: RESTORED FADE LOGIC ---
			# Calculates a ratio from 1.0 to 0.0 based on the time left
			var fade_ratio = max(0.0, pulse_timer / pulse_interval)
			
			# Smoothly fade the entire UI's opacity out to simulate a dying radar screen
			minimap_ui.modulate.a = lerp(minimap_ui.modulate.a, fade_ratio, delta * fade_speed)
			
			# Push the sweep progress into your GLSL shader!
			if minimap_ui.material:
				var progress = 1.0 - (pulse_timer / pulse_interval)
				minimap_ui.material.set_shader_parameter("sweep_progress", progress)

func trigger_pulse() -> void:
	pulse_timer = pulse_interval
	
	# 1. Snap the camera to Gordon's exact current location
	global_position = Vector3(
		player.global_position.x,
		100, 
		player.global_position.z
	)
	rotation.y = deg_to_rad(180)
		
	# 2. Snap the UI opacity back to 100% instantly
	if is_instance_valid(minimap_ui):
		minimap_ui.modulate.a = 1.0
		
	# 3. Take exactly ONE photograph of the world right now
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
