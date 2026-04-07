extends Camera3D

var player:Player


func _ready():
	player = get_tree().get_first_node_in_group('player')
	
func _physics_process(_delta: float) -> void:
	global_position = Vector3(
		player.global_position.x,
		100,
		player.global_position.z
	)
	rotation.y = player.rotation.y
