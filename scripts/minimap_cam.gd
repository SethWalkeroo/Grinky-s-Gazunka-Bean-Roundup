extends Camera3D

var player: CharacterBody3D
var minimap_ui: TextureRect

@onready var viewport: SubViewport = get_parent()
var texture_linked: bool = false

func _ready() -> void:
	# Force the camera to look straight down
	rotation_degrees.x = -90 
	player = get_tree().get_first_node_in_group('player')
	
	# Turn on the live 60fps video feed permanently!
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(player): return
	
	# Safely grab the minimap UI
	if not is_instance_valid(minimap_ui):
		minimap_ui = player.get_node_or_null("neck/head/eyes/CanvasLayer/circle_clip/minimap_rect")
		
	# Force the Viewport texture into the UI
	if is_instance_valid(minimap_ui) and not texture_linked:
		minimap_ui.texture = viewport.get_texture()
		texture_linked = true
		
	# Keep the screen fully bright, and turn off the glowing scanner ring 
	# (just in case the UI still has the shader material attached)
	if is_instance_valid(minimap_ui):
		minimap_ui.modulate.a = 1.0
		if minimap_ui.material:
			minimap_ui.material.set_shader_parameter("sweep_progress", 0.0)
			
	# ==========================================
	# STANDARD MINIMAP: LIVE TRACKING
	# ==========================================
	global_position = Vector3(
		player.global_position.x,
		100,
		player.global_position.z
	)
	
	# Keep North pointed UP so the map doesn't spin wildly.
	# (If you want the map to rotate with the player later, you can sync this to the player's rotation.y)
	rotation.y = deg_to_rad(180)
