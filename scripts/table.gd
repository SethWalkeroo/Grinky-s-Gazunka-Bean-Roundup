extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _on_hiding_area_body_entered(body: Node3D) -> void:
	if body is Player:
		body.is_hidden = true
		for voiceline in body.bean_pickup_voicelines.get_children():
			voiceline.stop()
		body.shh.play()


func _on_hiding_area_body_exited(body: Node3D) -> void:
	if body is Player:
		body.is_hidden = false
