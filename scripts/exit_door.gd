extends Area3D
@onready var icon_component: Node3D = $IconComponent


func _ready():
	icon_component.get_node('icon_sprite').pixel_size = 0.0007
