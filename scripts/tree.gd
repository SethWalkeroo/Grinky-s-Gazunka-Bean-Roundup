extends Node3D

@onready var branch_noise: AudioStreamPlayer3D = $branch_noise

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is Player:
		branch_noise.play()


func _on_area_3d_body_exited(body: Node3D) -> void:
	if body is Player:
		branch_noise.play()
