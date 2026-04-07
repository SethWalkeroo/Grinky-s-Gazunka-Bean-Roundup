extends CanvasLayer


@export var minimap_rect: TextureRect


func _ready():
	if !("heaven.tscn" in get_tree().current_scene.scene_file_path):
		var minimap_viewport:SubViewport = get_tree().current_scene.get_node('MinimapViewport')
		if minimap_rect:
			minimap_rect.texture = minimap_viewport.get_texture()


func show_screenshot_notification(path: String):
	var label = Label.new()
	label.text = "Screenshot saved: " + path.get_file()
	
	# Create a LabelSettings object for fine control
	var settings = LabelSettings.new()
	settings.font_size = 14 # Smaller font size
	settings.font_color = Color.WHITE
	settings.outline_size = 4
	settings.outline_color = Color.BLACK
	settings.shadow_size = 2
	settings.shadow_color = Color.BLACK
	settings.shadow_offset = Vector2(1, 1)
	
	label.label_settings = settings
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Add to the UI tree
	add_child(label)
	
	# Set to Bottom Center
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	
	# Move it slightly up from the absolute bottom edge so it's not cut off
	label.position.y -= 30 
	
	# Animation: Quick fade out
	var tween = create_tween()
	tween.tween_interval(1.5) # Show for 1.5 seconds
	tween.tween_property(label, "modulate:a", 0.0, 0.8) # Fade over 0.8 seconds
	tween.tween_callback(label.queue_free)
