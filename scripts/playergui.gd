extends CanvasLayer
class_name PlayerGUI

var player: CharacterBody3D

@export var minimap_rect: TextureRect

# --- HUD & EFFECTS ---
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

var master_bus = AudioServer.get_bus_index("Master")
var chase_music_bus = AudioServer.get_bus_index("chase_music")
var effects_bus = AudioServer.get_bus_index("effects")
var voicelines_bus = AudioServer.get_bus_index("game_voicelines")
var ambient_noise_bus = AudioServer.get_bus_index('ambient_noise')

func _ready():
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
	
	stamina_bar.value = 100
	if crosshair: crosshair.pivot_offset = crosshair.size / 2
	if inventory_menu: inventory_menu.visible = false

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

# --- REBIND LOGIC ---
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
	if "heaven.tscn" in get_tree().current_scene.scene_file_path: get_tree().change_scene_to_file("res://scenes/main.tscn")
	else: get_tree().reload_current_scene()

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

func _on_confirm_quit_pressed() -> void:
	GlobalStats.play_click()
	player.execute_quit()

func _on_main_menu_pressed() -> void:
	GlobalStats.play_click()
	if player.dead or (player.in_heaven or player.win):
		player.execute_quit()
	elif player.has_loot_to_lose():
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
