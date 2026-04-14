extends Button # Or TextureButton, depending on your node type

@export var speed: float = 0.5  # Adjust this to change how fast the rainbow cycles
var hue: float = 0.0

func _process(delta: float) -> void:
	# Increment hue based on time and speed
	hue += (delta * speed) / 7.777
	
	# Keep hue within the 0.0 to 1.0 range
	if hue > 1.0:
		hue -= 1.0
	
	# Create the new color (Saturation 1.0, Value 1.0 for bright colors)
	var new_color = Color.from_hsv(hue, 1.0, 1.0)
	
	# Apply to the button's self_modulate property
	self_modulate = new_color
