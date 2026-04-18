extends CanvasLayer
class_name PlayerGUI

var player: CharacterBody3D

@export var minimap_rect: TextureRect
const INVENTORY_SAVE_PATH = "user://player_inventory.json"
@onready var typing_sound: AudioStreamPlayer = $typing_sound
@onready var nvg_slot: ColorRect = $inventory_menu/nvg_slot

var hide_hotbar_setting: bool = false


# --- CRANK MINIGAME ---
@onready var crank_ui: Control = $crank_minigame_ui
@onready var crank_arm: ColorRect = $crank_minigame_ui/crank_arm
@onready var crank_sound: AudioStreamPlayer = $crank_minigame_ui/crank_sound
@onready var light_indicator: ColorRect = $crank_minigame_ui/flashlight_base/light_indicator


var is_cranking_ui_active: bool = false
var previous_mouse_angle: float = 0.0
var crank_speed: float = 0.0


# --- HUD & EFFECTS ---
@onready var mission_label: Label = $mission_label
@onready var proximity_distortion: ColorRect = $ProximityDistortion
@onready var damage_vignette: TextureRect = $damage_vignette
@onready var beans_found_label: Label = $beans_found_label
@onready var stamina_bar: ProgressBar = $stamina_bar
@onready var time: Label = $time
@onready var fade_rect: ColorRect = $fade_rect
@onready var win_label: Label = $win_label
@onready var exit_warning_label: Label = $exit_warning_label
@onready var crosshair: ColorRect = $crosshair/ColorRect
@onready var speed_lines: ColorRect = $SpeedLines
@onready var exhaustion_effect: ColorRect = $ExhaustionEffect
@onready var minimap: TextureRect = $circle_clip
@onready var wisp_cooldown: TextureProgressBar = $wisp_cooldown
@onready var flashlight_battery_bar: ProgressBar = $flashlight_battery_bar

# --- MENUS ---
@onready var quit_confirm_panel: ColorRect = $quit_confirm_panel
@onready var confirm_quit_btn: Button = $quit_confirm_panel/confirm_quit_btn
@onready var cancel_quit_btn: Button = $quit_confirm_panel/cancel_quit_btn
@onready var menu_vbox: VBoxContainer = $VBoxContainer
@onready var leaderboard_button: Button = $VBoxContainer/leaderboard_button
@onready var main_menu_button: Button = $VBoxContainer/main_menu
@onready var restart_button: Button = $VBoxContainer/restart_button
@onready var settings_panel: ColorRect = $settings_panel
@onready var video_settings: ColorRect = $video_settings
@onready var controls_settings: ColorRect = $controls_settings
@onready var controls_button: Button = $VBoxContainer/controls_button
@onready var controls_grid: GridContainer = $controls_settings/ScrollContainer/GridContainer
@onready var minimap_checkbox: CheckBox = $video_settings/VBoxContainer/HBoxContainer/minimap_checkbox
@onready var resume: Button = $VBoxContainer/resume

# --- INVENTORY UI ---
@onready var hotbar: Control = $Hotbar
@onready var slot_0: ColorRect = $Hotbar/slot0
@onready var slot_1: ColorRect = $Hotbar/slot1
@onready var slot_2: ColorRect = $Hotbar/slot2
@onready var slot_3: ColorRect = $Hotbar/slot3
@onready var inventory_menu: ColorRect = $inventory_menu
@onready var inventory_grid: GridContainer = $inventory_menu/GridContainer
@onready var hotbar_slots: Array = [slot_0, slot_1, slot_2, slot_3]

# --- SLIDERS ---
@onready var master_slider: HSlider = $settings_panel/VBoxContainer/HBoxContainer/master_slider
@onready var chase_music_slider: HSlider = $settings_panel/VBoxContainer/HBoxContainer2/chase_music_slider
@onready var effects_slider: HSlider = $settings_panel/VBoxContainer/HBoxContainer3/effects_slider
@onready var voicelines_slider: HSlider = $settings_panel/VBoxContainer/HBoxContainer4/voicelines_slider
@onready var ambient_noise_slider: HSlider = $settings_panel/VBoxContainer/HBoxContainer5/ambient_noise_slider

# --- STATE ---
var is_rebinding: bool = false
var action_to_rebind: String = ""
var button_to_rebind: Button = null
var leaderboard_scene = preload("res://scenes/leaderboard.tscn")
var pending_confirm_action: String

var master_bus = AudioServer.get_bus_index("Master")
var chase_music_bus = AudioServer.get_bus_index("chase_music")
var effects_bus = AudioServer.get_bus_index("effects")
var voicelines_bus = AudioServer.get_bus_index("game_voicelines")
var ambient_noise_bus = AudioServer.get_bus_index('ambient_noise')

func _ready():
	print(GlobalStats.came_from_main_menu)
	add_to_group("hud")
	
	if !("heaven.tscn" in get_tree().current_scene.scene_file_path):
		var minimap_viewport:SubViewport = get_tree().current_scene.get_node_or_null('MinimapViewport')
		if minimap_rect and minimap_viewport:
			minimap_rect.texture = minimap_viewport.get_texture()

func setup(p_player: CharacterBody3D):
	resume.visible = true
	player = p_player
	
	if quit_confirm_panel: quit_confirm_panel.visible = false
	if confirm_quit_btn: confirm_quit_btn.pressed.connect(_on_confirm_quit_pressed)
	if cancel_quit_btn: cancel_quit_btn.pressed.connect(_on_cancel_quit_pressed)

	minimap_checkbox.button_pressed = GlobalStats.minimap_on
	minimap.visible = GlobalStats.minimap_on

	sync_settings_from_global()

	if speed_lines: speed_lines.modulate.a = 0.0 
	if exhaustion_effect: exhaustion_effect.modulate.a = 0.0
	if controls_settings: controls_settings.visible = false

	if controls_button:
		controls_button.pressed.connect(_on_controls_button_pressed)
		controls_button.mouse_entered.connect(_play_hover_sound)

	if controls_grid:
		for action in GlobalStats.keybinds_to_save:
			var expected_btn_name = action.capitalize().replace(" ", "") + "Btn"
			var btn = controls_grid.get_node_or_null(expected_btn_name)
			if btn:
				btn.mouse_entered.connect(_play_hover_sound)
				btn.pressed.connect(_on_rebind_button_pressed.bind(btn, action))
				_update_button_text(btn, action)

		var save_controls_btn = controls_grid.get_node_or_null("save_settings")
		if save_controls_btn:
			save_controls_btn.mouse_entered.connect(_play_hover_sound)
			save_controls_btn.pressed.connect(_on_save_settings_pressed)

		var default_binds_btn = controls_grid.get_node_or_null("default_bindings")
		if default_binds_btn:
			default_binds_btn.mouse_entered.connect(_play_hover_sound)
			default_binds_btn.pressed.connect(_on_default_bindings_pressed)

	trigger_fade_in()
	if not("heaven.tscn" in get_tree().current_scene.scene_file_path):
		play_mission_intro()
	elif mission_label:
		mission_label.visible = false
	
	stamina_bar.value = 100
	if crosshair: crosshair.pivot_offset = crosshair.size / 2
	if inventory_menu: inventory_menu.visible = false

	# --- NEW: GREEN BATTERY BAR ---
	if flashlight_battery_bar:
		var green_style = StyleBoxFlat.new()
		green_style.bg_color = Color.GREEN
		flashlight_battery_bar.add_theme_stylebox_override("fill", green_style)

	for slot in player.get_all_ui_slots():
		if slot is Control:
			slot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

# --- VISUAL UPATERS ---
func sync_settings_from_global() -> void:
	if master_slider: master_slider.value = GlobalStats.master_vol
	if chase_music_slider: chase_music_slider.value = GlobalStats.menu_music_vol
	if effects_slider: effects_slider.value = GlobalStats.effects_vol
	if voicelines_slider: voicelines_slider.value = GlobalStats.voicelines_vol
	if ambient_noise_slider: ambient_noise_slider.value = GlobalStats.ambient_noise_vol

func trigger_fade_in():
	fade_rect.visible = true
	fade_rect.modulate.a = 1.0
	var fade_tween = create_tween()
	fade_tween.tween_property(fade_rect, "modulate:a", 0.0, 2.0)
	fade_tween.tween_callback(fade_rect.hide)

# --- THE COD 4 MISSION INTRO ---
func play_mission_intro() -> void:
	if not mission_label: return
	
	var target_text = "Location: Gordon's Dungeon\nMission: Collect all 7 beans and escape"
	
	# Setup the starting state (Invisible text, fully opaque node)
	mission_label.text = target_text
	mission_label.visible_characters = 0
	mission_label.modulate.a = 1.0
	mission_label.visible = true
	
	var total_chars = target_text.length()
	var type_speed = 0.05 # How fast each letter appears. Lower is faster!
	
	var tween = create_tween()
	
	# Start playing the typing sound right before the animation begins
	if typing_sound: 
		typing_sound.play()
	
	# 1. Type out the text letter by letter
	tween.tween_property(mission_label, "visible_characters", total_chars, total_chars * type_speed)
	
	# Stop the typing sound the exact millisecond the letters finish!
	if typing_sound: 
		tween.tween_callback(typing_sound.stop)
	
	# 2. Wait for 4 seconds so the player can read it
	tween.tween_interval(2.0)
	
	# 3. Smoothly fade the text into transparency over 2 seconds
	tween.tween_property(mission_label, "modulate:a", 0.0, 2.0)
	
	# 4. Hide the node entirely when finished
	tween.tween_callback(mission_label.hide)

# --- THE VICTORY SCREEN INTRO ---
func play_win_intro(report_text: String) -> void:
	if not win_label: return
	
	win_label.text = report_text
	win_label.visible_characters = 0
	win_label.modulate.a = 1.0
	win_label.visible = true
	
	var total_chars = report_text.length()
	var type_speed = 0.03 # Slightly faster than the mission intro!
	var tween = create_tween()
	
	if typing_sound: typing_sound.play()
	
	# 1. Type it out
	tween.tween_property(win_label, "visible_characters", total_chars, total_chars * type_speed)
	
	if typing_sound: tween.tween_callback(typing_sound.stop)
	
	# 2. Wait 5 seconds to read the stats
	tween.tween_interval(5.0)
	
	# 3. Fade it out smoothly
	tween.tween_property(win_label, "modulate:a", 0.0, 2.0)
	tween.tween_callback(win_label.hide)


func show_death_screen():
	if hotbar: hotbar.visible = false
	menu_vbox.modulate.a = 0.0
	menu_vbox.visible = true
	resume.visible = false
	menu_vbox.move_to_front()
	var btn_tween = create_tween().set_parallel(true)
	btn_tween.tween_property(menu_vbox, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE)

func update_hotbar(active_slot_index: int):
	for i in range(hotbar_slots.size()):
		var slot_rect = hotbar_slots[i]
		if i == active_slot_index: slot_rect.color = Color(0.8, 0.8, 0.2, 0.8)
		else: slot_rect.color = Color(0, 0, 0, 0.5)

func toggle_inventory(is_open: bool):
	if is_open:
		inventory_menu.visible = true
		crosshair.visible = false
	else:
		inventory_menu.visible = false
		crosshair.visible = true

func update_timers(total_time: float, speed_boost_timer: float, bean_count: int, delta: float, rainbow_speed: float):
	var m = int(total_time / 60.0)
	var s = int(fmod(total_time, 60.0))
	var ms = int(fmod(total_time, 1.0) * 1000.0)
	time.text = "%02d:%02d.%03d" % [m, s, ms] if total_time >= 60.0 else "%02d.%03d" % [s, ms]

	if speed_boost_timer > 0:
		if speed_lines: speed_lines.modulate.a = move_toward(speed_lines.modulate.a, 1.0, delta * 6.0)
	else:
		if speed_lines: speed_lines.modulate.a = move_toward(speed_lines.modulate.a, 0.0, delta * 1.2)

	if bean_count >= 7:
		var current_hue = wrapf(total_time * rainbow_speed, 0.0, 1.0)
		beans_found_label.add_theme_color_override("font_color", Color.from_hsv(current_hue, 1.0, 1.0))

func update_exhaustion(speed_boost_timer: float, is_exhausted: bool, delta: float):
	if not exhaustion_effect: return
	if speed_boost_timer > 0:
		exhaustion_effect.modulate.a = move_toward(exhaustion_effect.modulate.a, 0.0, delta * 3.0)
	elif is_exhausted:
		exhaustion_effect.modulate.a = move_toward(exhaustion_effect.modulate.a, 1.0, delta * 1.0)
	else:
		exhaustion_effect.modulate.a = move_toward(exhaustion_effect.modulate.a, 0.0, delta * 0.5)

func update_vignette(current_health: int, max_health: int, delta: float):
	if not damage_vignette: return
	if current_health < max_health:
		damage_vignette.modulate.a = 0.5 + (sin(Time.get_ticks_msec() / 150.0) * 0.2)
	else:
		damage_vignette.modulate.a = lerp(damage_vignette.modulate.a, 0.0, delta * 3.0)


# --- FLASHLIGHT METER ---
func update_flashlight_battery(current_battery: float, is_active: bool) -> void:
	if not flashlight_battery_bar: return
	flashlight_battery_bar.value = current_battery
	
	# --- NEW: LIGHT INDICATOR BRIGHTNESS ---
	if light_indicator:
		var battery_percent = clamp(current_battery / 100.0, 0.0, 1.0)
		light_indicator.color = Color(0.1, 0.1, 0.1).lerp(Color.WHITE, battery_percent)
	
	# --- THE VISIBILITY FIX ---
	# 1. Check if the flashlight is actively in the player's hand
	var is_equipped = false
	if player and player.active_slot_index != -1 and player.inventory.size() > player.active_slot_index:
		if player.inventory[player.active_slot_index] == "flashlight":
			is_equipped = true
			
	# 2. Only show the bar if it's equipped, turned on, or being cranked!
	if is_active or is_equipped or is_cranking_ui_active:
		flashlight_battery_bar.modulate.a = move_toward(flashlight_battery_bar.modulate.a, 1.0, 0.1)
	else:
		flashlight_battery_bar.modulate.a = move_toward(flashlight_battery_bar.modulate.a, 0.0, 0.1)
		
	# --- THE COLOR FIX ---
	# Retrieve the exact stylebox we made in setup() and physically change its color
	var fill_style = flashlight_battery_bar.get_theme_stylebox("fill") as StyleBoxFlat
	if fill_style:
		if current_battery < 20.0:
			fill_style.bg_color = Color.RED
		else:
			fill_style.bg_color = Color.GREEN


func update_proximity_distortion(distance: float, is_valid_enemy: bool, delta: float):
	if not proximity_distortion or not proximity_distortion.material: return
	var target_intensity = 0.0
	if is_valid_enemy and distance < 15.0:
		target_intensity = clamp(1.0 - ((distance - 3.0) / 12.0), 0.0, 1.0)
	var current_intensity = proximity_distortion.material.get_shader_parameter("intensity")
	if current_intensity == null: current_intensity = 0.0
	var new_intensity = move_toward(current_intensity, target_intensity, delta * 1.5)
	proximity_distortion.material.set_shader_parameter("intensity", new_intensity)

func show_screenshot_notification(path: String):
	var label = Label.new()
	label.text = "Screenshot saved: " + path.get_file()
	var settings = LabelSettings.new()
	settings.font_size = 14 
	settings.font_color = Color.WHITE
	settings.outline_size = 4
	settings.outline_color = Color.BLACK
	settings.shadow_size = 2
	settings.shadow_color = Color.BLACK
	settings.shadow_offset = Vector2(1, 1)
	label.label_settings = settings
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(label)
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	label.position.y -= 30 
	var tween = create_tween()
	tween.tween_interval(1.5) 
	tween.tween_property(label, "modulate:a", 0.0, 0.8) 
	tween.tween_callback(label.queue_free)

# --- REBIND & ESCAPE LOGIC ---
func handle_input(event: InputEvent) -> bool:
	if is_rebinding:
		if event is InputEventKey or event is InputEventMouseButton:
			if event.is_pressed():
				if event is InputEventKey and event.keycode == KEY_ESCAPE:
					is_rebinding = false
					_update_button_text(button_to_rebind, action_to_rebind)
					return true
				InputMap.action_erase_events(action_to_rebind)
				InputMap.action_add_event(action_to_rebind, event)
				is_rebinding = false
				_update_button_text(button_to_rebind, action_to_rebind)
				return true
		return true # Swallow inputs while rebinding

	# --- THE ESCAPE KEY INTERCEPT FIX ---
	# Look for the Escape key being pressed
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.is_pressed() and not event.is_echo():
		
		# 1. If the warning panel is open, automatically click "Cancel"
		if quit_confirm_panel and quit_confirm_panel.visible:
			_on_cancel_quit_pressed()
			return true # Tell player.gd we handled it, do NOT unpause the game!
			
		# 2. BONUS: If they are in the settings menus, automatically click "Save & Back"
		if is_in_sub_menus():
			_on_save_settings_pressed()
			return true # Tell player.gd we handled it, do NOT unpause the game!

	return false

func _update_button_text(btn: Button, action: String) -> void:
	var events = InputMap.action_get_events(action)
	var display_name = action.capitalize().replace("Leanleft", "Lean Left").replace("Leanright", "Lean Right").replace("Freelook", "Free Look")
	var key_name = "Unassigned"
	
	if events.size() > 0:
		key_name = events[0].as_text().get_slice(" (", 0).get_slice(" -", 0).strip_edges()

	var raw_text = display_name + ": " + key_name
	var bbcode_text = "[color=gray]" + display_name + ":[/color] [color=white]" + key_name + "[/color]"
	
	if is_rebinding and action_to_rebind == action:
		raw_text = "Press any key..."
		bbcode_text = "[color=yellow]Press any key...[/color]"

	btn.text = raw_text
	btn.add_theme_color_override("font_color", Color(0, 0, 0, 0))
	btn.add_theme_color_override("font_hover_color", Color(0, 0, 0, 0))
	btn.add_theme_color_override("font_pressed_color", Color(0, 0, 0, 0))
	btn.add_theme_color_override("font_focus_color", Color(0, 0, 0, 0))
	
	var rcl: RichTextLabel = btn.get_node_or_null("RichTextLabelOverlay")
	if not rcl:
		rcl = RichTextLabel.new()
		rcl.name = "RichTextLabelOverlay"
		rcl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rcl.bbcode_enabled = true
		rcl.scroll_active = false
		rcl.autowrap_mode = TextServer.AUTOWRAP_OFF
		rcl.fit_content = true
		btn.add_child(rcl)
		
	rcl.text = bbcode_text
	rcl.set_anchors_and_offsets_preset(Control.PRESET_CENTER)

func is_in_sub_menus() -> bool:
	return settings_panel.visible or video_settings.visible or controls_settings.visible

# --- MENU CALLBACKS ---
func _play_hover_sound():
	if player.button_hover_noise and not player.button_hover_noise.playing: player.button_hover_noise.play()

func _on_button_pressed():
	GlobalStats.play_click()
	if "heaven.tscn" in get_tree().current_scene.scene_file_path:
		print(GlobalStats.came_from_main_menu)
		if GlobalStats.came_from_main_menu:
			get_tree().reload_current_scene()
		else: 
			get_tree().change_scene_to_file("res://scenes/main.tscn")
	else:
		# --- THE EXPLOIT FIX WITH WARNING ---
		# Check if they are alive and actually have things to lose!
		if player and not player.dead and not player.win and player.has_method("has_loot_to_lose") and player.has_loot_to_lose():
			pending_confirm_action = "restart" # Tell the panel we want to restart
			menu_vbox.visible = false
			quit_confirm_panel.visible = true
		else:
			# If they have an empty backpack or are already dead, restart instantly
			if player and not player.dead and not player.win and player.has_method("wipe_inventory_on_death"):
				player.wipe_inventory_on_death()
			get_tree().reload_current_scene()

func _on_leaderboard_button_pressed() -> void:
	GlobalStats.play_click() 
	if get_tree().root.has_node("Leaderboard"): return
	if leaderboard_scene:
		var lb = leaderboard_scene.instantiate()
		lb.name = "Leaderboard"
		lb.process_mode = Node.PROCESS_MODE_ALWAYS
		lb.close_requested.connect(_handle_leaderboard_close.bind(lb))
		get_tree().root.add_child(lb)
		if lb is CanvasLayer: lb.layer = 100
		else:
			var wrapper = CanvasLayer.new()
			wrapper.name = "LeaderboardWrapper"
			wrapper.layer = 100
			lb.close_requested.connect(_handle_leaderboard_close.bind(wrapper))
			get_tree().root.add_child(wrapper)
			lb.reparent(wrapper)

func _handle_leaderboard_close(node_to_free):
	GlobalStats.play_click() 
	node_to_free.queue_free() 

func _on_cancel_quit_pressed() -> void:
	GlobalStats.play_click()
	quit_confirm_panel.visible = false
	menu_vbox.visible = true
	pending_confirm_action = ""

func _on_confirm_quit_pressed() -> void:
	GlobalStats.play_click()
	
	if pending_confirm_action == "restart":
		# They clicked Yes to restarting! Wipe the gear and reload.
		if player.has_method("wipe_inventory_on_death"):
			player.wipe_inventory_on_death()
		get_tree().reload_current_scene()
	else:
		# They clicked Yes to the Main Menu! Run the normal quit logic.
		player.execute_quit()

func _on_main_menu_pressed() -> void:
	GlobalStats.play_click()
	if player.dead or (player.in_heaven or player.win):
		player.execute_quit()
	elif player.has_loot_to_lose():
		pending_confirm_action = "quit" # <-- ADD THIS!
		menu_vbox.visible = false
		quit_confirm_panel.visible = true
	else:
		player.execute_quit()

func _on_settings_button_pressed() -> void:
	GlobalStats.play_click() 
	settings_panel.visible = true
	menu_vbox.visible = false

func _on_save_settings_pressed() -> void:
	GlobalStats.play_click()
	settings_panel.visible = false
	video_settings.visible = false
	controls_settings.visible = false
	menu_vbox.visible = true
	GlobalStats.minimap_on = minimap.visible
	GlobalStats.master_vol = master_slider.value
	GlobalStats.menu_music_vol = chase_music_slider.value 
	GlobalStats.effects_vol = effects_slider.value
	GlobalStats.voicelines_vol = voicelines_slider.value
	GlobalStats.ambient_noise_vol = ambient_noise_slider.value
	player.mouse_sens = GlobalStats.mouse_sens
	GlobalStats.save_to_disk()

func _on_video_button_pressed() -> void:
	GlobalStats.play_click()
	video_settings.visible = true
	menu_vbox.visible = false

func _on_controls_button_pressed() -> void:
	GlobalStats.play_click()
	menu_vbox.visible = false
	controls_settings.visible = true

func _on_rebind_button_pressed(btn: Button, action: String) -> void:
	GlobalStats.play_click()
	is_rebinding = true
	action_to_rebind = action
	button_to_rebind = btn
	_update_button_text(btn, action)

func _on_default_bindings_pressed() -> void:
	GlobalStats.play_click()
	InputMap.load_from_project_settings()
	for action in GlobalStats.keybinds_to_save:
		var expected_btn_name = action.capitalize().replace(" ", "") + "Btn"
		var btn = controls_grid.get_node_or_null(expected_btn_name)
		if btn: _update_button_text(btn, action)
	GlobalStats.save_to_disk()

func _on_resume_pressed() -> void:
	if player.dead: return
	if is_in_sub_menus():
		_on_save_settings_pressed()
		return 
	else:
		player.unpause_game()

func _on_check_box_toggled(toggled_on: bool) -> void:
	GlobalStats.play_click()
	minimap.visible = toggled_on
		
func _on_minimap_checkbox_toggled(_toggled_on: bool) -> void:
	GlobalStats.play_click()

func update_wisp_cooldown(current_time: float, max_time: float) -> void:
	if wisp_cooldown:
		wisp_cooldown.max_value = max_time
		wisp_cooldown.value = current_time
		
		if current_time <= 0.0:
			wisp_cooldown.visible = false
			wisp_cooldown.modulate.a = 0.0
		else:
			wisp_cooldown.visible = true
			
			# Fade IN during the first 0.3 seconds of the cooldown
			if current_time > max_time - 0.3:
				wisp_cooldown.modulate.a = (max_time - current_time) / 0.3
				
			# Fade OUT during the last 0.3 seconds of the cooldown
			elif current_time < 0.3:
				wisp_cooldown.modulate.a = current_time / 0.3
				
			# Keep it solid at 100% opacity the rest of the time
			else:
				wisp_cooldown.modulate.a = 1.0

# --- THE BULLETPROOF REFRESH ---
func refresh_inventory_ui() -> void:
	if not FileAccess.file_exists(INVENTORY_SAVE_PATH): 
		return
		
	var file = FileAccess.open(INVENTORY_SAVE_PATH, FileAccess.READ)
	
	# THE FIX: If the file is null (meaning it's locked), abort so we don't crash!
	if file == null:
		print("HUD ERROR: Couldn't open the JSON file. It might be locked!")
		return
		
	var json = JSON.new()
	
	if json.parse(file.get_as_text()) == OK:
		var save_data = json.get_data()
		file.close() # Always good practice for the HUD to close it too!
		
		# 1. Update the Backpack Grid
		if save_data.has("grid") and inventory_grid:
			var slots = inventory_grid.get_children()
			for i in range(min(save_data["grid"].size(), slots.size())):
				if slots[i].has_method("set_item"):
					# THE FIX: Force the quantity into an integer!
					var qty_as_int = int(save_data["grid"][i]["qty"])
					slots[i].set_item(save_data["grid"][i]["item"], qty_as_int)
					
		# 2. Update the Hotbar
		if save_data.has("hotbar"):
			for i in range(min(save_data["hotbar"].size(), hotbar_slots.size())):
				if hotbar_slots[i].has_method("set_item"):
					# THE FIX: Force the quantity into an integer!
					var qty_as_int = int(save_data["hotbar"][i]["qty"])
					hotbar_slots[i].set_item(save_data["hotbar"][i]["item"], qty_as_int)

# --- CRANK MINIGAME LOGIC ---
func toggle_crank_ui(show_ui: bool):
	is_cranking_ui_active = show_ui
	if crank_ui:
		crank_ui.visible = show_ui
		
	if show_ui and crank_arm:
		# Lock the starting angle so it doesn't jump wildly on the first frame
		var center_pos = crank_arm.global_position + (crank_arm.size / 2.0)
		previous_mouse_angle = center_pos.angle_to_point(get_viewport().get_mouse_position())
	elif not show_ui:
		crank_speed = 0.0
		if crank_sound and crank_sound.playing:
			crank_sound.stop()

# Godot will automatically run this every frame now!
func _process(delta: float) -> void:
# --- THE CRANK MINIGAME TRACKER ---
	var raw_speed = 0.0 # Define this outside the check so it defaults to 0 when closed!
	
	if is_cranking_ui_active and crank_arm and player:
		var center_pos = crank_arm.global_position + (crank_arm.size / 2.0)
		var current_mouse_pos = get_viewport().get_mouse_position()
		
		var current_angle = center_pos.angle_to_point(current_mouse_pos)
		var angle_diff = wrapf(current_angle - previous_mouse_angle, -PI, PI)
		
		if angle_diff > 0.0: 
			crank_arm.rotation = current_angle
			player.add_flashlight_battery(angle_diff * 2.5) 
			raw_speed = angle_diff / delta 
			
		previous_mouse_angle = current_angle
		
	# --- THE DYNAMIC AUDIO EFFECT (Now safely outside the UI check!) ---
	crank_speed = lerp(crank_speed, raw_speed, delta * 15.0)
	
	if crank_sound:
		if crank_speed > 1.0:
			if not crank_sound.playing:
				crank_sound.play()
				
			crank_sound.pitch_scale = clamp(0.7 + (crank_speed * 0.03), 0.6, 1.8)
			# THE FIX: Lowered the base volume from -20 to -35, and the max from 0 to -10!
			crank_sound.volume_db = clamp(-35.0 + (crank_speed * 1.0), -60.0, -10.0)
			
		else:
			# Rapidly fade the sound out to true silence when the mouse stops or UI closes
			crank_sound.volume_db = lerp(crank_sound.volume_db, -80.0, delta * 25.0)
			if crank_sound.volume_db <= -60.0 and crank_sound.playing:
				crank_sound.stop()

func hide_hud_for_heaven() -> void:
	# Hide the timer
	if time: 
		time.visible = false
		
	# Hide the new wisp cooldown we just made!
	if wisp_cooldown:
		wisp_cooldown.visible = false
		
	# --- IMPORTANT: UPDATE THESE NAMES! ---
	# I am guessing the variable names for your stamina and bean labels.
	# Make sure you change 'stamina_bar' and 'bean_label' to whatever 
	# they are actually called at the top of your playergui.gd script!
	if stamina_bar: 
		stamina_bar.visible = false
		
	if beans_found_label: 
		beans_found_label.visible = false

func _on_master_slider_value_changed(value: float) -> void: AudioServer.set_bus_volume_db(master_bus, linear_to_db(value))
func _on_chase_music_slider_value_changed(value: float) -> void: AudioServer.set_bus_volume_db(chase_music_bus, linear_to_db(value))
func _on_effects_slider_value_changed(value: float) -> void: AudioServer.set_bus_volume_db(effects_bus, linear_to_db(value))
func _on_voicelines_slider_value_changed(value: float) -> void: AudioServer.set_bus_volume_db(voicelines_bus, linear_to_db(value))
func _on_ambient_noise_slider_value_changed(value: float) -> void: AudioServer.set_bus_volume_db(ambient_noise_bus, linear_to_db(value))
