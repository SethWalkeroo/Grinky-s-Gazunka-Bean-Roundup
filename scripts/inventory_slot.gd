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
		set_item(player.inventory[index], 1 if player.inventory[index] != "empty" else 0)

func set_item(new_item: String, new_qty: int) -> void:
	item_name = new_item
	quantity = new_qty
	
	if item_name == "empty" or quantity <= 0:
		item_name = "empty"
		quantity = 0
		icon.texture = null
		qty_label.text = ""
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
			if player:
				qty_label.text = str(player.shotgun_ammo) + "/4"
		elif quantity > 1:
			qty_label.text = str(quantity)
		else:
			qty_label.text = ""

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

# --- LEFT CLICK DRAG (Standard) ---
func _get_drag_data(_at_position: Vector2) -> Variant:
	if item_name == "empty": return null
	
	var preview_ctrl = get_preview_control(item_name, quantity)
	set_drag_preview(preview_ctrl)
	
	# Change the global mouse cursor to the "grabbing" hand
	Input.set_default_cursor_shape(Input.CURSOR_DRAG)
	
	return {"source_slot": self, "dragged_item": item_name, "dragged_qty": quantity, "is_split": false}

# --- RIGHT CLICK DRAG (Split Stack) ---
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			right_click_down = event.pressed
			
	elif event is InputEventMouseMotion and right_click_down:
		if item_name != "empty" and quantity > 1 and item_name != "shotgun":
			right_click_down = false 
			var drag_qty = int(max(1.0, quantity / 2.0))
			
			var preview_ctrl = get_preview_control(item_name, drag_qty)
			
			active_drag_label = preview_ctrl.get_child(0).get_node("DragQtyLabel")
			active_drag_data = {"source_slot": self, "dragged_item": item_name, "dragged_qty": drag_qty, "is_split": true}
			
			# Change the global mouse cursor to the "grabbing" hand
			Input.set_default_cursor_shape(Input.CURSOR_DRAG)
			
			force_drag(active_drag_data, preview_ctrl)

# --- SCROLL WHEEL SPLIT ADJUSTMENT & AUTO-DROP ---
func _input(event: InputEvent) -> void:
	# Only the single slot that initiated the drag will run this code
	if active_drag_data.is_empty() or active_drag_label == null:
		return
		
	if event is InputEventMouseButton:
		# 1. SCROLL WHEEL ADJUSTMENT
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				# Prevent taking the entire stack (must leave 1 behind)
				if active_drag_data["dragged_qty"] < quantity - 1:
					active_drag_data["dragged_qty"] += 1
					active_drag_label.text = str(active_drag_data["dragged_qty"])
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				# Prevent dropping below 1
				if active_drag_data["dragged_qty"] > 1:
					active_drag_data["dragged_qty"] -= 1
					active_drag_label.text = str(active_drag_data["dragged_qty"])
					
		# 2. THE DROP HACK (Release Right-Click)
		elif event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed:
			# Inject a fake Left-Click release so Godot Native DND executes the drop!
			var fake_drop = InputEventMouseButton.new()
			fake_drop.button_index = MOUSE_BUTTON_LEFT
			fake_drop.pressed = false
			fake_drop.position = event.position
			fake_drop.global_position = event.global_position
			Input.parse_input_event(fake_drop)

# Cleans up the variables when the drag safely finishes or is cancelled
func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		active_drag_data.clear()
		active_drag_label = null
		right_click_down = false
		
		# Reset the global mouse cursor back to the standard arrow
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)

# --- DROP LOGIC ---
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.has("dragged_item")

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var source_slot = data["source_slot"]
	var incoming_item = data["dragged_item"]
	var incoming_qty = data["dragged_qty"]
	var is_split = data.get("is_split", false)
	
	# MERGE STACKS
	if item_name == incoming_item and item_name != "empty" and item_name != "shotgun":
		var space_left = MAX_STACK - quantity
		if space_left > 0:
			var amount_to_move = min(space_left, incoming_qty)
			quantity += amount_to_move
			source_slot.quantity -= amount_to_move
			
			self.set_item(item_name, quantity)
			source_slot.set_item(source_slot.item_name, source_slot.quantity)
	else:
		if is_split and item_name != "empty":
			return # Cancel drop if trying to swap a split stack into an occupied slot
			
		var my_old_item = item_name
		var my_old_qty = quantity
		
		self.set_item(incoming_item, incoming_qty)
		
		if is_split:
			source_slot.set_item(source_slot.item_name, source_slot.quantity - incoming_qty)
		else:
			source_slot.set_item(my_old_item, my_old_qty)
	
	if player and player.has_method("sync_inventory_arrays"):
		player.sync_inventory_arrays()
