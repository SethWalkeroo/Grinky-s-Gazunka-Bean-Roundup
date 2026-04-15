extends ColorRect

@onready var icon: TextureRect = $Icon
@onready var qty_label: Label = $QuantityLabel

var item_name: String = "empty"
var quantity: int = 0
const MAX_STACK: int = 16

var player: Node = null
var right_click_down: bool = false

# --- ACTIVE DRAG TRACKING (For Scroll Wheel) ---
var active_drag_data: Dictionary = {}
var active_drag_label: Label = null

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	if get_parent().name == "Hotbar":
		var index = name.right(1).to_int()
		if player and player.get("inventory"):
			set_item(player.inventory[index], 1 if player.inventory[index] != "empty" else 0)

func set_item(new_item: String, new_qty: int) -> void:
	item_name = new_item
	quantity = new_qty
	
	# Prevent guns with 0 ammo from deleting themselves
	if item_name == "empty" or (quantity <= 0 and item_name != "shotgun"):
		item_name = "empty"
		quantity = 0
		icon.texture = null
		qty_label.text = ""
		
		# --- THE FIX: RESET TO NORMAL ARROW ---
		mouse_default_cursor_shape = Control.CURSOR_ARROW 
	else:
		var tex_path = "res://icons/" + item_name + ".png"
		if ResourceLoader.exists(tex_path):
			icon.texture = load(tex_path)
			icon.modulate = Color(1, 1, 1)
		else:
			var placeholder = PlaceholderTexture2D.new()
			placeholder.size = Vector2(64, 64)
			icon.texture = placeholder
			icon.modulate = Color(1, 0, 1)
		
		if item_name == "shotgun":
			qty_label.text = str(quantity) + "/4"
		elif quantity > 1:
			qty_label.text = str(quantity)
		else:
			qty_label.text = ""
			
		# --- THE FIX: CHANGE TO POINTING HAND ---
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func refresh_label():
	set_item(item_name, quantity)

# --- PREVIEW GENERATOR (Builds the ghost image + number) ---
func get_preview_control(tex_name: String, drag_qty: int) -> Control:
	var preview = TextureRect.new()
	var tex_path = "res://icons/" + tex_name + ".png"
	if ResourceLoader.exists(tex_path):
		preview.texture = load(tex_path)
	else:
		var placeholder = PlaceholderTexture2D.new()
		placeholder.size = Vector2(64, 64)
		preview.texture = placeholder
		preview.modulate = Color(1, 0, 1)
		
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.custom_minimum_size = Vector2(64, 64)
	
	var label = Label.new()
	label.name = "DragQtyLabel"
	if drag_qty > 1 and tex_name != "shotgun":
		label.text = str(drag_qty)
		
	label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	
	preview.add_child(label)
	
	var preview_control = Control.new()
	preview_control.add_child(preview)
	preview.position = -preview.custom_minimum_size / 2
	return preview_control

# --- DRAG START ---
func _get_drag_data(_at_position: Vector2) -> Variant:
	# Prevent standard dragging if Shift is being held down!
	if item_name == "empty" or Input.is_key_pressed(KEY_SHIFT): return null
	
	var preview_ctrl = get_preview_control(item_name, quantity)
	set_drag_preview(preview_ctrl)
	
	Input.set_default_cursor_shape(Input.CURSOR_DRAG)
	GlobalStats.play_click()
	
	return {"source_slot": self, "dragged_item": item_name, "dragged_qty": quantity, "is_split": false}

# --- CLICK DETECTION (Shift-Click & Right-Click Split) ---
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
# --- SHIFT-CLICK TRANSFER ---
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and event.shift_pressed:
			if item_name != "empty":
				# 1. Check if we are in the main menu
				var main_scene = get_tree().current_scene
				if main_scene.has_method("shift_transfer_item"):
					main_scene.shift_transfer_item(self)
					return 
					
				# 2. Check if we are in-game and the player has the script!
				if player and player.has_method("shift_transfer_item"):
					player.shift_transfer_item(self)
					return

		if event.button_index == MOUSE_BUTTON_RIGHT:
			right_click_down = event.pressed
			
	elif event is InputEventMouseMotion and right_click_down:
		if item_name != "empty" and quantity > 1 and item_name != "shotgun":
			right_click_down = false 
			var drag_qty = int(max(1.0, quantity / 2.0))
			
			var preview_ctrl = get_preview_control(item_name, drag_qty)
			
			active_drag_label = preview_ctrl.get_child(0).get_node("DragQtyLabel")
			active_drag_data = {"source_slot": self, "dragged_item": item_name, "dragged_qty": drag_qty, "is_split": true}
			
			Input.set_default_cursor_shape(Input.CURSOR_DRAG)
			
			force_drag(active_drag_data, preview_ctrl)
			GlobalStats.play_click()

# --- SCROLL WHEEL SPLIT ADJUSTMENT & AUTO-DROP ---
func _input(event: InputEvent) -> void:
	if active_drag_data.is_empty() or active_drag_label == null:
		return
		
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				if active_drag_data["dragged_qty"] < quantity - 1:
					active_drag_data["dragged_qty"] += 1
					active_drag_label.text = str(active_drag_data["dragged_qty"])
					GlobalStats.play_click()
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				if active_drag_data["dragged_qty"] > 1:
					active_drag_data["dragged_qty"] -= 1
					active_drag_label.text = str(active_drag_data["dragged_qty"])
					GlobalStats.play_click()
					
		elif event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed:
			var fake_drop = InputEventMouseButton.new()
			fake_drop.button_index = MOUSE_BUTTON_LEFT
			fake_drop.pressed = false
			fake_drop.position = event.position
			fake_drop.global_position = event.global_position
			Input.parse_input_event(fake_drop)
			GlobalStats.play_click()

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		active_drag_data.clear()
		active_drag_label = null
		right_click_down = false
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)

# --- DROP LOGIC ---
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.has("dragged_item")

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var source_slot = data["source_slot"]
	var incoming_item = data["dragged_item"]
	var incoming_qty = data["dragged_qty"]
	var is_split = data.get("is_split", false)
	
	# --- THE EQUIPMENT LOCK ---
	# Reject anything that isn't the goggles from going in the face slot!
	if name == "nvg_slot" and incoming_item != "nightvision":
		GlobalStats.play_click() 
		return
	
	# --- DYNAMIC NODE FETCHING ---
	var current_player = get_tree().get_first_node_in_group("player")
	var main_scene = get_tree().current_scene

	# --- LOAD SHOTGUN BY DRAGGING AMMO ---
	if item_name == "shotgun" and incoming_item == "shotgun_ammo":
		
		# 1. IN-GAME CINEMATIC RELOAD INTERCEPT
		if current_player:
			if quantity >= 4:
				return # Gun is already full, do nothing!
				
			if get_parent().name != "Hotbar":
				# Gun is in the backpack grid, not the hotbar.
				# You can't reload a gun in your backpack!
				GlobalStats.play_click() 
				return
				
			# The gun is in the hotbar! Trigger the sequence.
			var slot_index = name.right(1).to_int()
			if current_player.has_method("force_reload_sequence"):
				current_player.force_reload_sequence(slot_index)
				
			return # ABORT THE INSTANT DROP! The animation handles the rest.

		# 2. MAIN MENU / STASH INSTANT RELOAD (Only runs if current_player is null)
		var space_left = 4 - quantity 
		if space_left > 0:
			var amount_to_load = min(space_left, incoming_qty)
			quantity += amount_to_load
			source_slot.quantity -= amount_to_load
			
			self.set_item("shotgun", quantity)
			source_slot.set_item(source_slot.item_name, source_slot.quantity)
			
			if main_scene and main_scene.has_method("play_inventory_pump_sound"):
				main_scene.play_inventory_pump_sound()
				
			if main_scene and main_scene.has_method("save_stash_to_json"):
				main_scene.save_stash_to_json()
			return
			

	if item_name == incoming_item and item_name == "shotgun_ammo":
		var space_left = MAX_STACK - quantity
		if space_left > 0:
			var amount_to_move = min(space_left, incoming_qty)
			quantity += amount_to_move
			source_slot.quantity -= amount_to_move
			
			self.set_item(item_name, quantity)
			source_slot.set_item(source_slot.item_name, source_slot.quantity)
	else:
		# --- SWAP ITEMS ---
		if is_split and item_name != "empty":
			return # Cancel drop if trying to swap a split stack into an occupied slot
			
		var my_old_item = item_name
		var my_old_qty = quantity
		
		self.set_item(incoming_item, incoming_qty)
		
		if is_split:
			source_slot.set_item(source_slot.item_name, source_slot.quantity - incoming_qty)
		else:
			source_slot.set_item(my_old_item, my_old_qty)
			
	GlobalStats.play_click()
	
	if current_player and current_player.has_method("sync_inventory_arrays"):
		current_player.sync_inventory_arrays()
