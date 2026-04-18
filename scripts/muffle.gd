extends AudioStreamPlayer3D

var player: Node3D
var raycast: RayCast3D

var base_volume: float
var base_bus: String 
var is_muffled: bool = false

# --- NEW: Corner Forgiveness ---
var lost_sight_timer: float = 0.0
@export var muffle_delay: float = 0.15 # Wait 0.15s before muffling to simulate sound wrapping around corners!

func _ready() -> void:
	base_volume = volume_db
	base_bus = bus 
	
	player = get_tree().get_first_node_in_group("player")
	
	raycast = RayCast3D.new()
	add_child(raycast)
	raycast.collision_mask = 1 
	
	# --- FIX 1: IGNORE THE ENEMY'S OWN BODY ---
	# 'owner' grabs the root node of the scene (e.g., the CharacterBody3D of Gordon)
	if owner is CollisionObject3D:
		raycast.add_exception(owner)
		
	# Just in case the audio node is parented to a specific bone or hitbox, ignore that too
	if get_parent() is CollisionObject3D and get_parent() != owner:
		raycast.add_exception(get_parent())


func _physics_process(delta: float) -> void:
	if not playing or not player: return

	raycast.target_position = to_local(player.global_position + Vector3(0, 1.5, 0))

	if raycast.is_colliding():
		# --- FIX 2: THE GRACE PERIOD ---
		# Start ticking the clock...
		lost_sight_timer += delta
		
		# Only muffle if the wall has blocked sight for longer than the delay!
		if not is_muffled and lost_sight_timer >= muffle_delay:
			is_muffled = true
			bus = "Muffled" 
			
			var tween = create_tween()
			tween.tween_property(self, "volume_db", base_volume - 3.0, 0.2)
	else:
		# CLEAR LINE OF SIGHT! Instantly reset the forgiveness clock.
		lost_sight_timer = 0.0
		
		# Restore the raw audio!
		if is_muffled:
			is_muffled = false
			bus = base_bus 
			
			var tween = create_tween()
			tween.tween_property(self, "volume_db", base_volume, 0.2)
