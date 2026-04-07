extends Node3D

@onready var foliage_sound: AudioStreamPlayer3D = $foliage_sound

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.



func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is Player:
		foliage_sound.play()
