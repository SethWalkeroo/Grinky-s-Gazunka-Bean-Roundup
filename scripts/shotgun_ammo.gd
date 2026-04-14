extends RigidBody3D

@export var ammo_amount: int = 1
var can_be_picked_up: bool = false

@onready var pickup_area: Area3D = $PickupArea

func _ready() -> void:
	# Wait half a second so it can bounce on the floor before being collectable!
	await get_tree().create_timer(0.5).timeout
	can_be_picked_up = true
	
	if pickup_area:
		pickup_area.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if not can_be_picked_up: return
	
	# Check if the thing that stepped on us is the player
	if body.is_in_group("player") and body.has_method("collect_item"):
		GlobalStats.pickup_sound()
		# Try to give the player the ammo
		var collected = body.collect_item("shotgun_ammo", ammo_amount)
		
		# If the player's backpack wasn't full, delete the physical item!
		if collected:
			queue_free()
