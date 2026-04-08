extends ColorRect

# Each slot needs a TextureRect child named "Icon"
@onready var icon: TextureRect = $Icon

# This holds whatever string item is in this slot (e.g., "shotgun", "medkit", "empty")
var item_name: String = "empty"

var player: Node = null

func _ready() -> void:
	# Find the player in the scene using the group we just made
	player = get_tree().get_first_node_in_group("player")
	
	# If this is a hotbar slot, grab the initial item from the player's inventory array
	if get_parent().name == "Hotbar":
		# Hacky but effective way to get the slot index from the name (e.g., "slot0" -> 0)
		var index = name.right(1).to_int() 
		set_item(player.inventory[index])

# Changes the data and updates the picture
func set_item(new_item: String) -> void:
	item_name = new_item
	if item_name == "empty":
		icon.texture = null
	else:
		# Assumes you have your item images saved in an "icons" folder!
		# Make sure you have a "res://icons/shotgun.png" ready to go.
		var tex_path = "res://icons/" + item_name + ".png"
		if ResourceLoader.exists(tex_path):
			icon.texture = load(tex_path)

# --- GODOT'S BUILT-IN DRAG & DROP FUNCTIONS ---

# 1. What happens when you click and drag this slot?
func _get_drag_data(_at_position: Vector2) -> Variant:
	if item_name == "empty": 
		return null # Can't drag nothing!
		
	# Create a little ghost image that follows your mouse
	var preview = TextureRect.new()
	preview.texture = icon.texture
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.custom_minimum_size = Vector2(64, 64)
	var preview_control = Control.new()
	preview_control.add_child(preview)
	preview.position = -preview.custom_minimum_size / 2
	set_drag_preview(preview_control)
	
	# Package up the data we are dragging (Who I am, and what I'm holding)
	return {"source_slot": self, "dragged_item": item_name}

# 2. Can we drop something onto this slot?
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	# Yes, as long as it's a dictionary containing our item data
	return typeof(data) == TYPE_DICTIONARY and data.has("dragged_item")

# 3. What happens when you let go of the mouse over this slot?
func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var source_slot = data["source_slot"]
	var incoming_item = data["dragged_item"]
	var my_old_item = item_name
	
	# Swap the items! I take yours, you take mine.
	source_slot.set_item(my_old_item)
	self.set_item(incoming_item)
	
	# Tell the player to update its backend arrays because the UI just changed
	if player and player.has_method("sync_inventory_arrays"):
		player.sync_inventory_arrays()
