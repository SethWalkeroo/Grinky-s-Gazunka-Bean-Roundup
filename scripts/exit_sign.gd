extends MeshInstance3D

# Adjust this to change how fast it scrolls
@export var scroll_speed: float = 0.555

var material: StandardMaterial3D

func _ready():
	# Get the material. Note: Ensure material is set to "Local to Scene" in Inspector
	material = get_active_material(0)

func _process(delta):
	if material:
		# Get the current offset
		var current_offset = material.uv1_offset
		
		# Add to the X component over time
		# Using delta ensures smooth movement regardless of frame rate
		current_offset.x += scroll_speed * delta
		
		# Apply the new offset
		material.uv1_offset = current_offset
