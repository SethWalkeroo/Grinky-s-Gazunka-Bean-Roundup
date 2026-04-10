extends ColorRect
@onready var purchase_made: AudioStreamPlayer = $"../../menu_noises/purchase_made"

# How many beans the player gets back per item
var sell_prices = {
	"shotgun": 25,
	"shotgun_ammo": 1 # 1 bean per individual shell
}

# 1. Tell Godot this box accepts inventory drops
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.has("dragged_item")

# 2. Execute the sale when the mouse is released
func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var source_slot = data["source_slot"]
	var item = data["dragged_item"]
	var qty = data["dragged_qty"]
	var is_split = data.get("is_split", false)

	# --- DEDUCT FROM INVENTORY ---
	if is_split:
		source_slot.set_item(source_slot.item_name, source_slot.quantity - qty)
	else:
		source_slot.set_item("empty", 0)

# --- ADD BEANS TO WALLET ---
	var total_earned = 0
	if item == "shotgun":
		# 25 beans for the gun itself, plus 1 bean for every shell loaded inside it!
		total_earned = sell_prices.get("shotgun", 25) + (qty * sell_prices.get("shotgun_ammo", 1))
	else:
		total_earned = sell_prices.get(item, 0) * qty
	
	GlobalStats.total_beans_collected += total_earned
	GlobalStats.save_to_disk()

	# --- FINISH TRANSACTION ---
	purchase_made.play()
	
	# Talk to the main menu script to update the UI and save the JSON
	var main_menu = get_tree().current_scene
	if main_menu.has_method("update_shop_display"):
		main_menu.update_shop_display()
	if main_menu.has_method("save_stash_to_json"):
		main_menu.save_stash_to_json()
