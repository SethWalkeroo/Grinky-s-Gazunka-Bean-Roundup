extends ColorRect

@onready var purchase_made: AudioStreamPlayer = $"../../menu_noises/purchase_made"

# How many beans the player gets back per item
var sell_prices = {
	"shotgun": 25,
	"shotgun_ammo": 1, # 1 bean per individual shell
	"flashlight": 7,
	"nightvision": 63
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

	# --- SAFETY CHECK: CAN WE SELL THIS? ---
	if not sell_prices.has(item):
		GlobalStats.play_click()
		return

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

	# --- NEW: TRIGGER FLOATING TEXT ---
	# Spawn the text at the exact mouse cursor location!
	spawn_floating_text(total_earned, get_global_mouse_position())

	# --- FINISH TRANSACTION ---
	purchase_made.play()
	
	# Talk to the main menu script to update the UI and save the JSON
	var main_menu = get_tree().current_scene
	if main_menu.has_method("update_shop_display"):
		main_menu.update_shop_display()
	if main_menu.has_method("save_stash_to_json"):
		main_menu.save_stash_to_json()

# --- THE NEW FLOATING TEXT FUNCTION ---
func spawn_floating_text(amount: int, start_pos: Vector2) -> void:
	if amount <= 0: return # Don't spawn text if they didn't earn anything!
	
	var popup = Label.new()
	popup.text = "+" + str(amount)
	
	# Make it look nice! Gold color with a slight black outline.
	popup.add_theme_color_override("font_color", Color.GOLD)
	popup.add_theme_font_size_override("font_size", 24)
	popup.add_theme_color_override("font_outline_color", Color.BLACK)
	popup.add_theme_constant_override("outline_size", 4)
	
	# Add it directly to the main scene so it draws OVER all the inventory panels
	get_tree().current_scene.add_child(popup)
	
	# Center the text exactly on the mouse cursor
	popup.global_position = start_pos - (popup.size / 2)
	
	var tween = get_tree().create_tween()
	
	# Move the text 60 pixels straight up over 1.2 seconds
	tween.tween_property(popup, "global_position:y", start_pos.y - 60.0, 1.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# Fade the text out at the exact same time
	tween.parallel().tween_property(popup, "modulate:a", 0.0, 1.2)
	
	# Delete the label so it doesn't clutter the game's memory
	tween.tween_callback(popup.queue_free)
