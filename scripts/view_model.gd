extends Camera3D


@onready var shotgun_rig: Node3D = $shotgun_rig
@onready var just_hands_rig: Node3D = $just_hands_rig

var current_rig = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	current_rig = shotgun_rig


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	return_to_og_position(current_rig, delta)
	

func sway(sway_amount):
	current_rig.position.x -= sway_amount.x * 0.000777
	current_rig.position.y += sway_amount.y * 0.000777
	
	

func return_to_og_position(fps_rig, delta):
	fps_rig.position.x = lerp(fps_rig.position.x, 0.0, delta*5)
	fps_rig.position.y = lerp(fps_rig.position.y, 0.0, delta*5)
