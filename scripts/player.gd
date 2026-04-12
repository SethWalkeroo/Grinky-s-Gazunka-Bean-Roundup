extends CharacterBody3D
class_name Player

#distortion
@onready var proximity_distortion: ColorRect = $neck/head/eyes/CanvasLayer/ProximityDistortion

#slide variables
# --- APEX SLIDE VARIABLES ---
var is_sliding: bool = false
var slide_boost_available: bool = true
var slide_cooldown_timer: float = 0.0 
@export var slide_cooldown: float = 1.2 
@export var slide_friction: float = 0.777
@export var slope_acceleration: float = 18.0 
@onready var slide_loop_sound: AudioStreamPlayer3D = $slide_loop_sound

# --- NEW DYNAMIC MOMENTUM VARIABLES ---
@export var sprint_acceleration: float = 7.777 # How fast you build up to max sprint speed
@export var slide_boost_multiplier: float = 0.85 # Multiplies your current speed to calculate the slide kick
#rotation tracking
var object_rotation_input: Vector2 = Vector2.ZERO

# quit confirm
# --- QUIT CONFIRMATION NODES ---

@onready var confirm_quit_btn: Button = $neck/head/eyes/CanvasLayer/quit_confirm_panel/confirm_quit_btn
@onready var cancel_quit_btn: Button = $neck/head/eyes/CanvasLayer/quit_confirm_panel/cancel_quit_btn
@onready var quit_confirm_panel: ColorRect = $neck/head/eyes/CanvasLayer/quit_confirm_panel


# new hiding logic
@export var active_enemy : Enemy
var is_hidden = false
@onready var shh: AudioStreamPlayer3D = $shh

#fps rig
@onready var view_model_camera: Camera3D = $neck/head/eyes/Camera3D/SubViewportContainer/SubViewport/view_model_camera

#shotgun sounds
@onready var shotgun_audio = view_model_camera.get_node('shotgun_rig/shotgun/shotgun_audio')

#shotgun impact on walls
@export var impact_scene: PackedScene

# --- INVENTORY & HOTBAR STATE ---
const SAVE_FILE_PATH = "user://player_inventory.json"
var inventory = ["shotgun", "empty", "empty", "empty"]
var active_slot_index: int = -1 # -1 means your hands are empty
var is_switching_weapons: bool = false
var inventory_open: bool = false

# --- WEAPON STATE ---
var shotgun_ammo: int = 4
var is_reloading: bool = false
var is_chambered: bool = true
var cancel_reload: bool = false

@onready var hotbar: Control = $neck/head/eyes/CanvasLayer/Hotbar
@onready var slot_0: ColorRect = $neck/head/eyes/CanvasLayer/Hotbar/slot0
@onready var slot_1: ColorRect = $neck/head/eyes/CanvasLayer/Hotbar/slot1
@onready var slot_2: ColorRect = $neck/head/eyes/CanvasLayer/Hotbar/slot2
@onready var slot_3: ColorRect = $neck/head/eyes/CanvasLayer/Hotbar/slot3
@onready var inventory_menu: ColorRect = $neck/head/eyes/CanvasLayer/inventory_menu
@onready var inventory_grid: GridContainer = $neck/head/eyes/CanvasLayer/inventory_menu/GridContainer

@onready var hotbar_slots: Array = [
	slot_0,
	slot_1,
	slot_2,
	slot_3
]

# Adjust these paths to point exactly to your shotgun model and its AnimationPlayer!
@onready var shotgun_model: Node3D = view_model_camera.get_node('shotgun_rig')
@onready var shotgun_animator: AnimationPlayer = view_model_camera.get_node('shotgun_rig/shotgun/AnimationPlayer')

# --- B-HOP STATE ---
var bhop_jump_buffer: float = 0.0
const BHOP_BUFFER_MAX: float = 0.15 # 150ms window to buffer a jump
const SOURCE_AIR_ACCEL: float = 12.0 # Gives you that smooth air-strafing feel
var jump_cooldown: float = 0.0

@onready var gui: CanvasLayer = $neck/head/eyes/CanvasLayer
@onready var wall_torches: Node3D = get_node_or_null("../wall_torches")

@onready var button_hover_noise: AudioStreamPlayer = $button_hover_noise
@onready var button_click_noise: AudioStreamPlayer = $button_click_noise
@onready var video_settings: ColorRect = $neck/head/eyes/CanvasLayer/video_settings
@onready var minimap: TextureRect = $neck/head/eyes/CanvasLayer/circle_clip
@onready var exit_warning_voiceline: AudioStreamPlayer3D = $exit_warning_voiceline
@onready var all_seven_beans_voiceline: AudioStreamPlayer3D = $all_seven_beans_voiceline
@onready var crosshair: ColorRect = $neck/head/eyes/CanvasLayer/crosshair/ColorRect
@onready var out_of_breath_sound: AudioStreamPlayer3D = $out_of_breath_sound
@onready var speed_lines: ColorRect = $neck/head/eyes/CanvasLayer/SpeedLines
@onready var exhaustion_effect: ColorRect = $neck/head/eyes/CanvasLayer/ExhaustionEffect

# --- EXPORTS & CONFIG ---
@export var min_grab_distance: float = 1.0 
@export var max_grab_distance: float = 2.0
@export var scroll_speed: float = 0.2
@export var throw_force: float = 8.0
@export var object_rotation_sens: float = 0.2
@export var rainbow_speed: float = 0.25

@export var walking_speed: float = 5.0
@export var sprinting_speed: float = 8.2 
@export var crouching_speed: float = 3.0
@export var jump_velocity: float = 4.5
@export var lerp_speed: float = 10.0
@export var air_lerp_speed: float = 3.0
@export var neck_lerp_speed: float = 7.777
@export var mouse_sens: float = 0.4
@export var slide_sens: float = 0.3
@export var slide_speed: float = 10.0

@export var lean_distance: float = 1
@export var lean_angle: float = 8.0
@export var lean_speed: float = 8.0

@export var stamina_drain_sprint: float = 0.35 
@export var stamina_regen_idle: float = 0.15 
@export var stamina_regen_move: float = 0.05 
@export var exhaustion_penalty_duration: float = 3.0 
## TWEAK: How much stamina is recovered when picking up a Gazunka Bean
@export var bean_stamina_boost: float = 25.0 

# --- Speed Boost Config ---
@export var bean_speed_boost_amount: float = 1.5 
@export var bean_speed_boost_duration: float = 2.0
var speed_boost_timer: float = 0.0

# --- SIGNALS & STATE ---
signal bean_collected
signal player_paused
signal player_unpaused

var bonus_beans = 0
var rotating_object = false
var bean_count = 0
var win = false
var paused: bool = false
var dead: bool = false
var in_heaven = false

var current_speed: float = 5.0
const default_mouse_sens: float = 0.4
var direction: Vector3 = Vector3.ZERO
var last_velocity: Vector3 = Vector3.ZERO
var crouching_depth: float = -0.5
var free_look_angle_amt: float = 2.0
var current_lean_offset: float = 0.0
var current_lean_tilt: float = 0.0

var walking: bool = false
var sprinting: bool = false
var crouching: bool = false
var free_looking: bool = false
var sliding: bool = false
var slide_timer: float = 0.0
var slide_timer_max: float = 1.0
var slide_vector: Vector2 = Vector2.ZERO

var stamina_delay_timer: float = 0.0
const STAMINA_DELAY_MAX: float = 1.2
var is_exhausted: bool = false
var exhaustion_timer: float = 0.0

const head_bobbing_sprinting_speed: float = 22.0
const head_bobbing_walking_speed: float = 14.0
const head_bobbing_crouching_speed: float = 10.0
const head_bobbing_sprinting_intensity: float = 0.2
const head_bobbing_walking_intensity: float = 0.1
const head_bobbing_crouching_intensity: float = 0.05
var head_bobbing_vector: Vector2 = Vector2.ZERO
var head_bobbing_index: float = 0.0
var head_bobbing_current_intensity: float = 0.0
var previous_eye_position: float = 0.0

var total_time: float = 0.0
var grabbed_object = null
var final_time: String = "" 

# --- FOOTPRINT NODES ---
@export var footprint_scene: PackedScene
@export var footprint_spacing: float = 0.15
@onready var footprint_raycast: RayCast3D = $footprint_raycast

var is_left_foot: bool = true 

# --- ONREADY NODES ---
@onready var beans_found_label: Label = $neck/head/eyes/CanvasLayer/beans_found_label
@onready var grabbed_anchor: Marker3D = $neck/head/eyes/SpringArm3D/GrabbedAnchor
@onready var object_grabber_shapecast: ShapeCast3D = $neck/head/eyes/object_grabber_shapecast
@onready var stamina_bar: ProgressBar = $neck/head/eyes/CanvasLayer/stamina_bar
@onready var time: Label = $neck/head/eyes/CanvasLayer/time
@onready var fade_rect: ColorRect = $neck/head/eyes/CanvasLayer/fade_rect
@onready var win_label: Label = $neck/head/eyes/CanvasLayer/win_label
@onready var exit_warning_label: Label = $neck/head/eyes/CanvasLayer/exit_warning_label
@onready var menu_vbox: VBoxContainer = $neck/head/eyes/CanvasLayer/VBoxContainer
@onready var leaderboard_button: Button = $neck/head/eyes/CanvasLayer/VBoxContainer/leaderboard_button
@onready var main_menu_button: Button = $neck/head/eyes/CanvasLayer/VBoxContainer/main_menu
@onready var restart_button: Button = $neck/head/eyes/CanvasLayer/VBoxContainer/restart_button
@onready var settings_panel: ColorRect = $neck/head/eyes/CanvasLayer/settings_panel

@onready var master_slider: HSlider = $neck/head/eyes/CanvasLayer/settings_panel/VBoxContainer/HBoxContainer/master_slider
@onready var effects_slider: HSlider = $neck/head/eyes/CanvasLayer/settings_panel/VBoxContainer/HBoxContainer3/effects_slider
@onready var voicelines_slider: HSlider = $neck/head/eyes/CanvasLayer/settings_panel/VBoxContainer/HBoxContainer4/voicelines_slider
@onready var chase_music_slider: HSlider = $neck/head/eyes/CanvasLayer/settings_panel/VBoxContainer/HBoxContainer2/chase_music_slider
@onready var ambient_noise_slider: HSlider = $neck/head/eyes/CanvasLayer/settings_panel/VBoxContainer/HBoxContainer5/ambient_noise_slider

@onready var timer: Timer = $Timer
@onready var bean_pickup_voicelines: Node3D = $bean_pickup_voicelines
@onready var slide_sound: AudioStreamPlayer3D = $slide_sound
@onready var grab_spring_arm: SpringArm3D = $neck/head/eyes/SpringArm3D
@onready var jump_sound: AudioStreamPlayer3D = $jump_sound
@onready var throw_sound: AudioStreamPlayer3D = $throw_sound

@onready var head: Node3D = $neck/head
@onready var standing_collision_shape: CollisionShape3D = $standing_collision_shape
@onready var crouching_collision_shape: CollisionShape3D = $crouching_collision_shape
@onready var ceiling_detection: RayCast3D = $ceiling_detection
@onready var neck: Node3D = $neck
@onready var camera_3d: Camera3D = $neck/head/eyes/Camera3D
@onready var eyes: Node3D = $neck/head/eyes
@onready var animation_player: AnimationPlayer = $neck/head/eyes/AnimationPlayer

@onready var start_voiceline: AudioStreamPlayer3D = $neck/head/eyes/test_voiceline
@onready var footsteps: AudioStreamPlayer3D = $footsteps

# Audio Buses
var master_bus = AudioServer.get_bus_index("Master")
var chase_music_bus = AudioServer.get_bus_index("chase_music")
var effects_bus = AudioServer.get_bus_index("effects")
var voicelines_bus = AudioServer.get_bus_index("game_voicelines")
var ambient_noise_bus = AudioServer.get_bus_index('ambient_noise')

# Dynamic Nodes
var exit_door: Area3D = null
var gazunka_beans: Node3D = null
var enemy_doors: Node3D = null
var open_noise: AudioStreamPlayer3D = null
var leaderboard_scene = preload("res://scenes/leaderboard.tscn")

@onready var menu_container: VBoxContainer = $neck/head/eyes/CanvasLayer/VBoxContainer
@onready var minimap_checkbox: CheckBox = $neck/head/eyes/CanvasLayer/video_settings/VBoxContainer/HBoxContainer/minimap_checkbox

# --- CONTROLS REBINDING NODES & STATE ---
@onready var controls_button: Button = $neck/head/eyes/CanvasLayer/VBoxContainer/controls_button
@onready var controls_settings: ColorRect = $neck/head/eyes/CanvasLayer/controls_settings
@onready var controls_grid: GridContainer = $neck/head/eyes/CanvasLayer/controls_settings/ScrollContainer/GridContainer

var is_rebinding: bool = false
var action_to_rebind: String = ""
var button_to_rebind: Button = null

func _ready() -> void:
	# --- INITIALIZE QUIT POPUP ---
	if quit_confirm_panel: quit_confirm_panel.visible = false
	if confirm_quit_btn:
		confirm_quit_btn.pressed.connect(_on_confirm_quit_pressed)
	if cancel_quit_btn:
		cancel_quit_btn.pressed.connect(_on_cancel_quit_pressed)
	
	#subviewport fps camera
	$neck/head/eyes/Camera3D/SubViewportContainer/SubViewport.size = DisplayServer.window_get_size()

	minimap_checkbox.button_pressed = GlobalStats.minimap_on
	minimap.visible = GlobalStats.minimap_on
	grab_spring_arm.add_excluded_object(self)
	object_grabber_shapecast.add_exception(self)
	footprint_raycast.add_exception(self)
	
	sync_settings_from_global()
	
	if speed_lines:
		speed_lines.modulate.a = 0.0 
	if exhaustion_effect:
		exhaustion_effect.modulate.a = 0.0

	if controls_settings:
		controls_settings.visible = false
		
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
	
	fade_rect.visible = true
	fade_rect.modulate.a = 1.0
	var fade_tween = get_tree().create_tween()
	fade_tween.tween_property(fade_rect, "modulate:a", 0.0, 2.0)
	fade_tween.tween_callback(fade_rect.hide)
	
	stamina_bar.value = 100
	
	if crosshair:
		crosshair.pivot_offset = crosshair.size / 2
		
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if "heaven.tscn" in get_tree().current_scene.scene_file_path:
		setup_heaven()
	else:
		setup_level()
		
	# --- INITIALIZE HOTBAR & WEAPON STATE ---
	if inventory_menu: inventory_menu.visible = false
	if shotgun_model: shotgun_model.visible = false
		
	load_inventory()
	
	update_hotbar_ui()
	refresh_all_slots()
	
	for slot in get_all_ui_slots():
		if slot is Control:
			slot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func sync_settings_from_global() -> void:
	mouse_sens = GlobalStats.mouse_sens
	if master_slider: master_slider.value = GlobalStats.master_vol
	if chase_music_slider: chase_music_slider.value = GlobalStats.menu_music_vol
	if effects_slider: effects_slider.value = GlobalStats.effects_vol
	if voicelines_slider: voicelines_slider.value = GlobalStats.voicelines_vol
	if ambient_noise_slider: ambient_noise_slider.value = GlobalStats.ambient_noise_vol

func setup_heaven() -> void:
	in_heaven = true
	time.visible = false
	beans_found_label.visible = false
	stamina_bar.visible = false
	
	if GlobalStats.needs_upload:
		upload_new_best_score()
		
	if not GlobalStats.came_from_main_menu:
		if win_label:
			var report = "Final Time: " + GlobalStats.final_time_string
			report += "\nPersonal Best: " + GlobalStats.best_time_string
			if GlobalStats.final_time_string == GlobalStats.best_time_string:
				report += "\nNEW PERSONAL RECORD!"
				
			# --- DOPAMINE UPGRADE: SHOW THE MONEY ---
			report += "\n\nTotal Profit: +" + str(GlobalStats.last_run_profit) + " Beans!"
			if GlobalStats.final_time < 120.0:
				report += " (2x Speed Bonus!)"
				
			win_label.text = report
			win_label.visible = true
			win_label.modulate.a = 1.0
			check_global_record()
			
			var tween = get_tree().create_tween()
			tween.tween_interval(5.0)
			tween.tween_property(win_label, "modulate:a", 0.0, 2.0)
			tween.tween_callback(win_label.hide)
	else:
		if win_label: 
			win_label.visible = false

func setup_level() -> void:
	exit_door = get_node_or_null("../exit_door")
	gazunka_beans = get_node_or_null("../Gazunka_Beans")
	enemy_doors = get_node_or_null("../enemy_doors")
	open_noise = get_node_or_null("../open_noise")
	if win_label: win_label.visible = false
	start_voiceline.play()
	
	# TURN REVERB BACK ON FOR THE DUNGEON
	var effects_bus = AudioServer.get_bus_index("effects")
	for i in range(AudioServer.get_bus_effect_count(effects_bus)):
		if AudioServer.get_bus_effect(effects_bus, i) is AudioEffectReverb:
			AudioServer.set_bus_effect_enabled(effects_bus, i, true)
			
	var voice_bus = AudioServer.get_bus_index("game_voicelines")
	for i in range(AudioServer.get_bus_effect_count(voice_bus)):
		if AudioServer.get_bus_effect(voice_bus, i) is AudioEffectReverb:
			AudioServer.set_bus_effect_enabled(voice_bus, i, true)

func upload_new_best_score():
	var sw_result = await SilentWolf.Scores.get_scores(100, "main").sw_get_scores_complete
	var scores = sw_result.scores
	for score_data in scores:
		if score_data.player_name == GlobalStats.player_name:
			var target_id = score_data.score_id 
			SilentWolf.Scores.delete_score(target_id)
			await get_tree().create_timer(0.2).timeout 
			
	var final_score = snapped(GlobalStats.best_time_float, 0.01)
	SilentWolf.Scores.save_score(GlobalStats.player_name, final_score, "main")
	GlobalStats.needs_upload = false

func check_global_record():
	var sw_result = await SilentWolf.Scores.get_scores(10, "main").sw_get_scores_complete
	var scores = sw_result.scores
	if scores.size() > 0:
		var fastest_time = float(scores[0].score)
		for score_data in scores:
			var current_score_in_list = float(score_data.score)
			if current_score_in_list < fastest_time:
				fastest_time = current_score_in_list
		
		var my_time = GlobalStats.final_time
		if my_time < fastest_time - 0.001:
			win_label.text += "\nNEW GLOBAL RECORD!"
			win_label.add_theme_color_override("font_color", Color.CHARTREUSE)
	else:
		win_label.text += "\nNEW GLOBAL RECORD!"
		win_label.add_theme_color_override("font_color", Color.CHARTREUSE)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("screenshot"):
			GlobalStats.play_click()
			await get_tree().process_frame
			
			var capture = get_viewport().get_texture().get_image()
			var sys_time = Time.get_datetime_string_from_system().replace(":", "_")
			var filename = "user://screenshot_" + sys_time + ".png"
			
			capture.save_png(filename)
			
			if gui:
				gui.show_screenshot_notification(filename)
				
			print("Screenshot saved to: ", ProjectSettings.globalize_path(filename))
	
	if is_rebinding:
		if event is InputEventKey or event is InputEventMouseButton:
			if event.is_pressed():
				if event is InputEventKey and event.keycode == KEY_ESCAPE:
					is_rebinding = false
					_update_button_text(button_to_rebind, action_to_rebind)
					get_viewport().set_input_as_handled()
					return
				
				InputMap.action_erase_events(action_to_rebind)
				InputMap.action_add_event(action_to_rebind, event)
				
				is_rebinding = false
				_update_button_text(button_to_rebind, action_to_rebind)
				get_viewport().set_input_as_handled()
		return
		
	if event.is_action_pressed('pause') and !paused and !dead:
		if inventory_open:
			toggle_inventory()
			
		GlobalStats.play_click()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		emit_signal('player_paused')
		menu_vbox.visible = true
		menu_vbox.move_to_front()
		paused = true
		if hotbar: hotbar.visible = false
		return
	elif event.is_action_pressed('pause') and paused and !dead:
		if settings_panel.visible or video_settings.visible or controls_settings.visible:
			_on_save_settings_pressed()
			return 
		else:
			GlobalStats.play_click()
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			emit_signal('player_unpaused')
			menu_vbox.visible = false
			settings_panel.visible = false
			paused = false
			if hotbar: hotbar.visible = true
			return
			
	if event is InputEventKey and event.is_pressed() and not event.is_echo() and not paused and not dead:
		if event.keycode == KEY_TAB:
			GlobalStats.play_click()
			toggle_inventory()
		
	if dead or paused or inventory_open: return

	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_1:
			equip_slot(0)
		elif event.keycode == KEY_2:
			equip_slot(1)
		elif event.keycode == KEY_3:
			equip_slot(2)
		elif event.keycode == KEY_4:
			equip_slot(3)
		elif event.keycode == KEY_R:
			reload_shotgun()

# --- INTERACT & FIRE LOGIC ---
	if event.is_action_pressed('interact'):
		if active_slot_index != -1 and inventory[active_slot_index] == "shotgun":
			# --- THE FIX: RELOAD CANCEL ---
			if is_reloading:
				cancel_reload = true
			else:
				fire_shotgun()
		else:
			if grabbed_object:
				grabbed_object = null
				rotating_object = false
			elif object_grabber_shapecast.is_colliding():
				for i in object_grabber_shapecast.get_collision_count():
					var collided = object_grabber_shapecast.get_collider(i)
					if (collided is RigidBody3D or collided is PhysicalBone3D) and !grabbed_object:
						var space_state = get_world_3d().direct_space_state
						var query = PhysicsRayQueryParameters3D.create(eyes.global_position, collided.global_position)
						query.exclude = [self.get_rid(), collided.get_rid()]
						query.collision_mask = 1 
						
						var hit_wall = space_state.intersect_ray(query)
						if not hit_wall:
							try_grabbing(collided)
							break

	if event is InputEventMouseMotion:
		if rotating_object and grabbed_object:
			object_rotation_input += event.relative
		else:
			if free_looking:
				neck.rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
				neck.rotation.y = clamp(neck.rotation.y, deg_to_rad(-135), deg_to_rad(135))
			else:
				rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
				head.rotate_x(deg_to_rad(-event.relative.y * mouse_sens))
				head.rotation.x = clamp(head.rotation.x, deg_to_rad(-98), deg_to_rad(98))
				view_model_camera.sway(Vector2(event.relative.x, event.relative.y))

	if event is InputEventMouseButton:
		if grabbed_object:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				grab_spring_arm.spring_length = clamp(grab_spring_arm.spring_length + scroll_speed, min_grab_distance, max_grab_distance)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				grab_spring_arm.spring_length = clamp(grab_spring_arm.spring_length - scroll_speed, min_grab_distance, max_grab_distance)
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			rotating_object = event.pressed

# --- INVENTORY UI LOGIC ---
func toggle_inventory() -> void:
	inventory_open = !inventory_open
	if inventory_open:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		if inventory_menu: inventory_menu.visible = true
		crosshair.visible = false
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		if inventory_menu: inventory_menu.visible = false
		crosshair.visible = true

func fire_shotgun() -> void:
	if is_switching_weapons or is_reloading: return
	
	if shotgun_animator.is_playing() and (shotgun_animator.current_animation == "fire" or shotgun_animator.current_animation == "pump"):
		return
		
	if shotgun_ammo > 0:
		shotgun_ammo -= 1
		hotbar_slots[active_slot_index].quantity = shotgun_ammo
		var flash = view_model_camera.get_node_or_null('shotgun_rig/shotgun/muzzle_flash')
		if flash:
			flash.visible = true
			var flash_timer = get_tree().create_timer(0.05)
			flash_timer.timeout.connect(func(): flash.visible = false)
			
		trigger_screen_shake(0.2, "shotgun")
		
		var knockback_dir = camera_3d.global_transform.basis.z.normalized()
		knockback_dir += Vector3(0, 0.2, 0) 
		velocity += knockback_dir * 4.0 
		
		var space_state = get_world_3d().direct_space_state
		var origin = camera_3d.global_position
		
		var pellets = 8          
		var spread_amount = 0.08 
		var range_distance = 50.0 
		
		var shot_excludes = [self.get_rid()]
		if is_instance_valid(gazunka_beans):
			for bean in gazunka_beans.get_children():
				if is_instance_valid(bean) and bean is CollisionObject3D:
					shot_excludes.append(bean.get_rid())
		
		for i in range(pellets):
			var spread_offset = Vector3(
				randf_range(-spread_amount, spread_amount), 
				randf_range(-spread_amount, spread_amount), 
				randf_range(-spread_amount, spread_amount)
			)
			
			var pellet_direction = (-camera_3d.global_transform.basis.z + spread_offset).normalized()
			var end_point = origin + (pellet_direction * range_distance)
			
			var query = PhysicsRayQueryParameters3D.create(origin, end_point)
			query.exclude = shot_excludes 
			
			var result = space_state.intersect_ray(query)
			
			if result:
				if impact_scene:
					var impact = impact_scene.instantiate()
					get_tree().current_scene.add_child(impact)
					impact.global_position = result.position
					
					var hit_normal = result.normal
					if hit_normal != Vector3.UP and hit_normal != Vector3.DOWN:
						impact.look_at(result.position + hit_normal, Vector3.UP)
					elif hit_normal == Vector3.UP:
						impact.rotation_degrees.x = 90
					elif hit_normal == Vector3.DOWN:
						impact.rotation_degrees.x = -90
						
					var surface_type = "default"
					var hit_node = result.collider
					
					if hit_node is GridMap:
						if hit_normal.is_equal_approx(Vector3.UP):
							surface_type = "wood"
						else:
							surface_type = "stone" 
							
					elif hit_node.is_in_group("wood"):
						surface_type = "wood"
					elif hit_node.is_in_group("metal"):
						surface_type = "metal"
					elif hit_node.is_in_group("flesh") or hit_node is Enemy:
						surface_type = "flesh"
					
					if impact.has_method("play_impact"):
						impact.play_impact(surface_type)
						
				# --- DYNAMIC HEADSHOT & DAMAGE LOGIC ---
				var hit_node = result.collider
				var is_headshot = false

				if hit_node is PhysicalBone3D and "Head" in hit_node.name:
					is_headshot = true
					var temp_node = hit_node
					while temp_node and not temp_node is Enemy:
						temp_node = temp_node.get_parent()
					if temp_node is Enemy:
						hit_node = temp_node

				elif hit_node is Enemy:
					var local_y = result.position.y - hit_node.global_position.y
					print("Pellet hit height: ", local_y)
					if local_y > 2.5:
						is_headshot = true
						
				if hit_node and hit_node.has_method("take_damage"):
					var hit_distance = origin.distance_to(result.position)
					var pellet_damage = remap(hit_distance, 0.0, range_distance, 15.0, 2.0)
					
					if is_headshot:
						pellet_damage *= 2.5
						
					var final_damage = int(clamp(pellet_damage, 2.0, 50.0))
					hit_node.take_damage(final_damage, result.position, is_headshot)
					
				if result.collider is RigidBody3D or result.collider is PhysicalBone3D:
					if result.collider is RigidBody3D:
						result.collider.freeze = false
						result.collider.gravity_scale = 1.0 
						result.collider.sleeping = false 

					var push_dir = -camera_3d.global_transform.basis.z.normalized()
					result.collider.apply_impulse(push_dir * 50.0, result.position - result.collider.global_position) 

		if shotgun_animator.has_animation("fire"):
			shotgun_animator.play("fire")
			shotgun_audio.get_node('fire').play()
			await shotgun_animator.animation_finished
			
		if shotgun_animator.has_animation("pump"):
			shotgun_animator.play("pump")
			shotgun_audio.get_node('pump').play()
			
		if shotgun_ammo > 0:
			is_chambered = true
		else:
			is_chambered = false
			
		refresh_all_slots() 
	else:
		shotgun_audio.get_node('click').play()
		print("Click! Out of ammo.")

func reload_shotgun() -> void:
	if is_switching_weapons or is_reloading: return
	if active_slot_index == -1 or inventory[active_slot_index] != "shotgun": return
	if shotgun_ammo >= 4: return # Already full
	
	var ammo_available = get_total_item_count("shotgun_ammo")
	if ammo_available <= 0:
		print("No ammo in inventory to reload with!")
		return
		
	is_reloading = true
	cancel_reload = false
	var shells_needed = 4 - shotgun_ammo
	var shells_to_load = min(shells_needed, ammo_available)
	
	if shotgun_animator.has_animation("begin_reload"):
		shotgun_animator.play("begin_reload", 0.05)
		await shotgun_animator.animation_finished
		
	for i in range(shells_to_load):
		if cancel_reload: break
		
		if shotgun_animator.has_animation("inserting_shells"):
			shotgun_animator.play("inserting_shells", 0.05)
			shotgun_audio.get_node('load_shell').play()
			await shotgun_animator.animation_finished
			
		# Physically add the shell we just finished animating
		shotgun_ammo += 1
		hotbar_slots[active_slot_index].quantity = shotgun_ammo
		consume_item("shotgun_ammo", 1) 
		refresh_all_slots()
		
		# Did the player click while that shell was being loaded? Abort the loop!
		if cancel_reload: break
		await get_tree().process_frame
		
	if shotgun_animator.has_animation("end_reload"):
		shotgun_animator.play("end_reload", 0.05)
		await shotgun_animator.animation_finished
		
	if not is_chambered and shotgun_ammo > 0:
		if shotgun_animator.has_animation("pump"):
			shotgun_animator.play("pump", 0.05)
			shotgun_audio.get_node('pump').play()
			await shotgun_animator.animation_finished
		is_chambered = true
		
	is_reloading = false
	cancel_reload = false

# --- NEW INVENTORY BACKEND HELPERS ---

func get_all_ui_slots() -> Array:
	var all = []
	all.append_array(hotbar_slots)
	if inventory_grid:
		all.append_array(inventory_grid.get_children())
	return all

func get_total_item_count(target_item: String) -> int:
	var total = 0
	for slot in get_all_ui_slots():
		if slot.item_name == target_item:
			total += slot.quantity
	return total

func consume_item(target_item: String, amount: int) -> void:
	var amount_left_to_remove = amount
	for slot in get_all_ui_slots():
		if slot.item_name == target_item and slot.quantity > 0:
			if slot.quantity >= amount_left_to_remove:
				slot.set_item(slot.item_name, slot.quantity - amount_left_to_remove)
				return
			else:
				amount_left_to_remove -= slot.quantity
				slot.set_item("empty", 0)

func refresh_all_slots():
	for slot in get_all_ui_slots():
		if slot.has_method("refresh_label"):
			slot.refresh_label()

func sync_inventory_arrays() -> void:
	var old_held_item = "empty"
	if active_slot_index != -1:
		old_held_item = inventory[active_slot_index]
		
	for i in range(hotbar_slots.size()):
		inventory[i] = hotbar_slots[i].item_name
		
	if active_slot_index != -1:
		var current_held_item = inventory[active_slot_index]
		
		if current_held_item == 'shotgun' and old_held_item == 'shotgun':
			shotgun_ammo = hotbar_slots[active_slot_index].quantity
			is_chambered = (shotgun_ammo > 0)
		
		if current_held_item != old_held_item:
			if current_held_item == "empty":
				if shotgun_model.visible and shotgun_animator.has_animation("put_away"):
					shotgun_animator.play("put_away")
					shotgun_audio.get_node('put_away').play()
					await shotgun_animator.animation_finished
				shotgun_model.visible = false
				active_slot_index = -1
				update_hotbar_ui()
			else:
				var temp = active_slot_index
				active_slot_index = -1 
				equip_slot(temp)

# --- CONTROLS MENU CALLBACKS ---
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
		if btn:
			_update_button_text(btn, action)
			
	GlobalStats.save_to_disk()

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

func try_grabbing(collided):
	if !collided or grabbed_object == collided: return
	
	if gazunka_beans and collided in gazunka_beans.get_children():
		handle_bean_pickup(collided)
		return

	if wall_torches and collided in wall_torches.get_children():
		if collided is RigidBody3D:
			collided.freeze = false
			collided.gravity_scale = 1.0

	grabbed_object = collided
	add_collision_exception_with(grabbed_object)
	
	if "sleeping" in grabbed_object:
		grabbed_object.sleeping = false 
		
	grab_spring_arm.spring_length = 2.0

func handle_bean_pickup(collided):
	speed_boost_timer = bean_speed_boost_duration
	if is_exhausted:
		is_exhausted = false
		stamina_bar.modulate = Color.WHITE
		if out_of_breath_sound.playing: out_of_breath_sound.stop()

	if collided.has_node("pickup_noise"):
		var sfx = collided.get_node("pickup_noise")
		collided.remove_child(sfx)
		get_tree().current_scene.add_child(sfx)
		sfx.global_position = collided.global_position
		
		# --- DOPAMINE UPGRADE: DYNAMIC PITCH SHIFTING ---
		# Each bean makes the pickup sound slightly higher pitched!
		sfx.pitch_scale = 1.0 + (bean_count * 0.08)
		
		sfx.play()
		sfx.finished.connect(sfx.queue_free)

	if collided.has_node("GPUParticles3D"):
		var p = collided.get_node("GPUParticles3D")
		var pos = p.global_position
		collided.remove_child(p)
		get_tree().current_scene.add_child(p)
		p.global_position = pos
		p.emitting = true
		var timer_p = get_tree().create_timer(p.lifetime)
		timer_p.timeout.connect(p.queue_free)
	
	bean_found()
	spawn_floating_text(collided.global_position, "+1 Gazunka Bean!", Color(0.955, 1.0, 0.043, 1.0))
	collided.queue_free()
	
	if grabbed_object == collided: 
		if grabbed_object.has_meta("original_mask"):
			grabbed_object.collision_mask = grabbed_object.get_meta("original_mask")
		remove_collision_exception_with(grabbed_object)
		grabbed_object = null

func _physics_process(delta: float) -> void:
	$neck/head/eyes/Camera3D/SubViewportContainer/SubViewport/view_model_camera.global_transform = camera_3d.global_transform

	if dead or paused or inventory_open: 
		if dead:
			final_time = time.text
			GlobalStats.final_time = total_time 
			GlobalStats.final_time_string = time.text
			timer.stop()
		return

	update_crosshair(delta)
	handle_timers(delta)
	handle_interaction()
	handle_movement(delta)
	handle_camera_and_bobbing(delta)
	handle_grabbed_object(delta)
	check_bean_proximity()
	update_exhaustion_visuals(delta)
	update_proximity_distortion(delta)

func update_crosshair(delta: float) -> void:
	if not crosshair: return
	
	var is_interactable = false
	var is_enemy = false
	
	if object_grabber_shapecast.is_colliding():
		for i in object_grabber_shapecast.get_collision_count():
			var collided = object_grabber_shapecast.get_collider(i)
			if collided is RigidBody3D:
				var space_state = get_world_3d().direct_space_state
				var query = PhysicsRayQueryParameters3D.create(camera_3d.global_position, collided.global_position)
				query.exclude = [self.get_rid(), collided.get_rid()]
				query.collision_mask = 1 
				
				var hit_wall = space_state.intersect_ray(query)
				if not hit_wall:
					is_interactable = true
					break
				
	var space_state = get_world_3d().direct_space_state
	var origin = camera_3d.global_position
	var end_point = origin + (-camera_3d.global_transform.basis.z * 50.0) 
	
	var query = PhysicsRayQueryParameters3D.create(origin, end_point)
	query.exclude = [self.get_rid()]
	
	var result = space_state.intersect_ray(query)
	if result:
		if result.collider is Enemy or result.collider.is_in_group("flesh"):
			is_enemy = true
			
	var target_color = Color.WHITE
	var target_size = Vector2(1.0, 1.0)
	
	if is_enemy:
		target_color = Color.RED
		target_size = Vector2(1.5, 1.5)
	elif is_interactable:
		target_color = Color.GREEN
		target_size = Vector2(2.0, 2.0)
	
	crosshair.color = lerp(crosshair.color, target_color, delta * 20.0)
	crosshair.size = lerp(crosshair.size, target_size, delta * 20.0)

func update_exhaustion_visuals(delta: float) -> void:
	if not exhaustion_effect: return
	if speed_boost_timer > 0:
		exhaustion_effect.modulate.a = move_toward(exhaustion_effect.modulate.a, 0.0, delta * 3.0)
	elif is_exhausted:
		exhaustion_effect.modulate.a = move_toward(exhaustion_effect.modulate.a, 1.0, delta * 1.0)
	else:
		exhaustion_effect.modulate.a = move_toward(exhaustion_effect.modulate.a, 0.0, delta * 0.5)

func handle_timers(delta: float) -> void:
	total_time += delta
	var m = int(total_time / 60.0)
	var s = int(fmod(total_time, 60.0))
	var ms = int(fmod(total_time, 1.0) * 1000.0)
	time.text = "%02d:%02d.%03d" % [m, s, ms] if total_time >= 60.0 else "%02d.%03d" % [s, ms]

	if speed_boost_timer > 0:
		speed_boost_timer -= delta
		if speed_lines: speed_lines.modulate.a = move_toward(speed_lines.modulate.a, 1.0, delta * 6.0)
	else:
		if speed_lines: speed_lines.modulate.a = move_toward(speed_lines.modulate.a, 0.0, delta * 1.2)

	if bean_count >= 7:
		if exit_door and exit_door.has_node("light"):
			exit_door.get_node("light").light_color = Color.GREEN
		var current_hue = wrapf(total_time * rainbow_speed, 0.0, 1.0)
		beans_found_label.add_theme_color_override("font_color", Color.from_hsv(current_hue, 1.0, 1.0))

func handle_interaction() -> void:
	if Input.is_action_pressed('voiceline'): start_voiceline.play()
	
	if Input.is_action_just_pressed("interact2") and grabbed_object:
		throw_sound.pitch_scale = randf_range(1.0, 1.2)
		throw_sound.play()
		var throw_dir = -eyes.global_basis.z + Vector3(0.0, 0.2, 0.0)
		
		if "sleeping" in grabbed_object:
			grabbed_object.sleeping = false
			
		var final_impulse = throw_dir.normalized() * throw_force * grabbed_object.mass
		var drop_obj = grabbed_object
		
		remove_collision_exception_with(drop_obj)
		
		grabbed_object = null
		rotating_object = false
		drop_obj.apply_central_impulse(final_impulse)
		drop_obj.angular_velocity *= 0.1

func handle_movement(delta: float) -> void:
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	var speed_multiplier = 1.0
	if speed_boost_timer > 0: speed_multiplier = bean_speed_boost_amount
	
	if slide_cooldown_timer > 0.0:
		slide_cooldown_timer -= delta
		
	var speed_length = Vector2(velocity.x, velocity.z).length()
	
	# --- STAMINA LOGIC ---
	if in_heaven:
		stamina_bar.value = 100
	else:
		if is_exhausted:
			exhaustion_timer -= delta
			stamina_bar.value = 1.0 
			var blink = (sin(Time.get_ticks_msec() * 0.02) + 1.0) / 2.0
			stamina_bar.modulate = Color(1, 0, 0).lerp(Color(1, 0.6, 0.6), blink)
			if exhaustion_timer <= 0:
				is_exhausted = false
				stamina_bar.modulate = Color.WHITE
				stamina_bar.value = 0.0
				if out_of_breath_sound.playing: out_of_breath_sound.stop()
		
		if sprinting and input_dir != Vector2.ZERO and !is_exhausted:
			stamina_bar.value -= stamina_drain_sprint
			stamina_delay_timer = STAMINA_DELAY_MAX 
		else:
			if stamina_delay_timer > 0: stamina_delay_timer -= delta 
			elif !is_exhausted: 
				if input_dir == Vector2.ZERO: stamina_bar.value += stamina_regen_idle
				elif crouching or walking: stamina_bar.value += stamina_regen_move

		if stamina_bar.value <= 0 and !is_exhausted: trigger_exhaustion()

	# --- FIXED CROUCHING & SLIDING TRIGGER ---
	if Input.is_action_pressed('crouch') or is_sliding or (crouching and ceiling_detection.is_colliding()):
		if is_on_floor():
			current_speed = lerp(current_speed, crouching_speed * speed_multiplier, delta * lerp_speed)
			
		head.position.y = lerp(head.position.y, crouching_depth, delta * lerp_speed)
		standing_collision_shape.disabled = true
		crouching_collision_shape.disabled = false
		
		var minimum_slide_speed = (walking_speed + 0.5) * speed_multiplier
		
		if ((speed_length > minimum_slide_speed and is_on_floor()) or is_sliding) and !is_exhausted:
			
			if is_on_floor() and slide_boost_available and slide_cooldown_timer <= 0.0:
				slide_sound.play()
				if not in_heaven: stamina_bar.value -= 10
				
				var move_dir = -transform.basis.z
				move_dir.y = 0
				
				var dynamic_boost = speed_length * slide_boost_multiplier
				velocity += move_dir.normalized() * dynamic_boost
				
				slide_boost_available = false 
				slide_cooldown_timer = slide_cooldown 
				free_looking = true
				
			is_sliding = true
			mouse_sens = slide_sens
		else:
			is_sliding = false 
			mouse_sens = default_mouse_sens
			
		walking = false; sprinting = false; crouching = true
		
	elif !ceiling_detection.is_colliding():
		standing_collision_shape.disabled = false; crouching_collision_shape.disabled = true
		head.position.y = lerp(head.position.y, 0.0, (delta * lerp_speed) * 0.8)
		
		is_sliding = false
		mouse_sens = default_mouse_sens
		if not Input.is_action_pressed("crouch"):
			slide_boost_available = true 
			
		if Input.is_action_pressed('sprint') and !is_exhausted and (stamina_bar.value != 0 or in_heaven):
			current_speed = move_toward(current_speed, sprinting_speed * speed_multiplier, delta * sprint_acceleration)
			walking = false; sprinting = true; crouching = false
		else:
			current_speed = lerp(current_speed, walking_speed * speed_multiplier, delta * lerp_speed)
			walking = true; sprinting = false; crouching = false

	# --- DOPAMINE UPGRADE: SLIDE FOV WARP ---
	var target_fov = 75.0
	if is_sliding: target_fov = 85.0
	camera_3d.fov = lerp(camera_3d.fov, target_fov, delta * 6.0)

	# --- GRAVITY & JUMPING ---
	if not is_on_floor(): velocity += get_gravity() * delta
	
	if jump_cooldown > 0: jump_cooldown -= delta
	
	if Input.is_action_just_pressed("jump"): bhop_jump_buffer = BHOP_BUFFER_MAX
	if bhop_jump_buffer > 0: bhop_jump_buffer -= delta

	if bhop_jump_buffer > 0 and is_on_floor() and !ceiling_detection.is_colliding() and jump_cooldown <= 0.0:
		if is_exhausted and not in_heaven:
			if !out_of_breath_sound.playing: out_of_breath_sound.play()
		else:
			if not in_heaven: stamina_bar.value -= 5
			velocity.y = jump_velocity
			is_sliding = false
			free_looking = false
			bhop_jump_buffer = 0.0
			jump_cooldown = 0.25
			jump_sound.play()
			animation_player.play('jumping')

	if is_on_floor() and last_velocity.y < -3.0:
		animation_player.play('landing')
		footsteps.play()
		spawn_landing_footprints()

	# --- DIRECTION & VELOCITY MATH ---
	var target_dir = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if is_on_floor():
		if is_sliding:
			var floor_normal = get_floor_normal()
			if floor_normal.y < 0.99: 
				var downhill_dir = Vector3.DOWN.slide(floor_normal).normalized()
				velocity += downhill_dir * slope_acceleration * delta
			else: 
				var friction_amount = slide_friction * delta * 15.0
				var flat_vel = Vector2(velocity.x, velocity.z)
				if in_heaven and target_dir != Vector3.ZERO:
					var current_slide_speed = flat_vel.length()
					var desired_direction = Vector2(target_dir.x, target_dir.z).normalized() * current_slide_speed
					flat_vel = flat_vel.lerp(desired_direction, delta * 4.0)
				flat_vel = flat_vel.move_toward(Vector2.ZERO, friction_amount)
				velocity.x = flat_vel.x
				velocity.z = flat_vel.y
				
			if Vector2(velocity.x, velocity.z).length() < 1.0:
				is_sliding = false
		else:
			if in_heaven and bhop_jump_buffer > 0:
				direction = target_dir if target_dir != Vector3.ZERO else direction
			else:
				direction = lerp(direction, target_dir, delta * lerp_speed)
	else:
		if in_heaven and target_dir != Vector3.ZERO:
			direction = lerp(direction, target_dir, delta * SOURCE_AIR_ACCEL)
		elif target_dir != Vector3.ZERO:
			direction = lerp(direction, target_dir, delta * air_lerp_speed)
		
	# --- MOMENTUM PRESERVATION & BRAKES ---
	if not is_sliding:
		var flat_vel = Vector2(velocity.x, velocity.z)
		
		if direction:
			var target_vel = Vector2(direction.x, direction.z) * current_speed
			
			if flat_vel.length() > current_speed:
				if not is_on_floor():
					var high_speed_target = Vector2(direction.x, direction.z).normalized() * flat_vel.length()
					flat_vel = flat_vel.lerp(high_speed_target, delta * 6.0)
					
					var new_length = move_toward(flat_vel.length(), current_speed, 5.0 * delta)
					flat_vel = flat_vel.normalized() * new_length
				else:
					var deceleration = 15.0 * delta
					if crouching:
						deceleration = 40.0 * delta 
						
					flat_vel = flat_vel.move_toward(target_vel, deceleration)
					
				velocity.x = flat_vel.x
				velocity.z = flat_vel.y
			else:
				velocity.x = target_vel.x
				velocity.z = target_vel.y
		else:
			if in_heaven and not is_on_floor(): pass
			else:
				var decel = 15.0 * delta
				if crouching and is_on_floor(): 
					decel = 40.0 * delta 
				elif flat_vel.length() <= current_speed: 
					if is_on_floor():
						decel = current_speed
					else:
						decel = 2.0 * delta
				
				velocity.x = move_toward(velocity.x, 0, decel)
				velocity.z = move_toward(velocity.z, 0, decel)
				
	# --- DYNAMIC SLIDING AUDIO ---
	if is_sliding and is_on_floor():
		if not slide_loop_sound.playing:
			slide_loop_sound.play()
		
		var current_slide_speed = Vector2(velocity.x, velocity.z).length()
		
		var target_pitch = clamp(current_slide_speed / 10.0, 0.7, 1.3)
		slide_loop_sound.pitch_scale = lerp(slide_loop_sound.pitch_scale, target_pitch, delta * 10.0)
		
		var target_volume = -40.0 + (clamp(current_slide_speed / 15.0, 0.0, 1.0) * 40.0)
		slide_loop_sound.volume_db = lerp(slide_loop_sound.volume_db, target_volume, delta * 15.0)
		
	else:
		if slide_loop_sound.playing:
			slide_loop_sound.volume_db = lerp(slide_loop_sound.volume_db, -60.0, delta * 25.0)
			if slide_loop_sound.volume_db <= -50.0:
				slide_loop_sound.stop()
					
	last_velocity = velocity
	move_and_slide()

func trigger_exhaustion():
	is_exhausted = true
	exhaustion_timer = exhaustion_penalty_duration
	if !out_of_breath_sound.playing: out_of_breath_sound.play()
	for line in bean_pickup_voicelines.get_children():
		if line.playing: line.stop()
	if all_seven_beans_voiceline.playing: all_seven_beans_voiceline.stop()
	if start_voiceline.playing: start_voiceline.stop()

func handle_camera_and_bobbing(delta: float) -> void:
	var lean_input = Input.get_axis("leanright", "leanleft")
	var target_lean = -lean_input * lean_distance
	
	if lean_input != 0:
		var space_state = get_world_3d().direct_space_state
		var ray_start = head.global_position
		var ray_end = ray_start + (head.global_transform.basis.x * target_lean)
		var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
		var excludes = [self.get_rid()]
		if is_instance_valid(grabbed_object) and grabbed_object is CollisionObject3D:
			excludes.append(grabbed_object.get_rid())
		query.exclude = excludes
		var result = space_state.intersect_ray(query)
		if result:
			var safe_dist = max(0.0, ray_start.distance_to(result.position) - 0.2)
			target_lean = sign(target_lean) * safe_dist

	current_lean_offset = lerp(current_lean_offset, target_lean, delta * lean_speed)
	current_lean_tilt = lerp(current_lean_tilt, lean_input * deg_to_rad(lean_angle), delta * lean_speed)
	
	if Input.is_action_pressed('freelook') or sliding: free_looking = true
	else:
		free_looking = false
		neck.rotation.y = lerp(neck.rotation.y, 0.0, delta * neck_lerp_speed)
		
	if sliding:
		slide_timer -= delta
		if slide_timer <= 0:
			mouse_sens = default_mouse_sens
			sliding = false; free_looking = false
		
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	
	if input_dir != Vector2.ZERO and is_on_floor() and !sliding:
		if sprinting:
			head_bobbing_current_intensity = head_bobbing_sprinting_intensity
			head_bobbing_index += head_bobbing_sprinting_speed * delta
		elif walking:
			head_bobbing_current_intensity = head_bobbing_walking_intensity
			head_bobbing_index += head_bobbing_walking_speed * delta
		elif crouching:
			head_bobbing_current_intensity = head_bobbing_crouching_intensity
			head_bobbing_index += head_bobbing_crouching_speed * delta
			
		head_bobbing_vector.y = sin(head_bobbing_index)
		head_bobbing_vector.x = sin(head_bobbing_index / 2) + 0.5
		eyes.position.y = lerp(eyes.position.y, head_bobbing_vector.y * (head_bobbing_current_intensity) / 2, delta * lerp_speed)
		eyes.position.x = lerp(eyes.position.x, current_lean_offset + (head_bobbing_vector.x * (head_bobbing_current_intensity)), delta * lerp_speed)
		
		if previous_eye_position < 0 and eyes.position.y > 0:
			footsteps.play()
			spawn_footprint()
		previous_eye_position = eyes.position.y
	else:
		head_bobbing_index = 0.0 
		eyes.position.y = lerp(eyes.position.y, 0.0, delta * lerp_speed)
		eyes.position.x = lerp(eyes.position.x, current_lean_offset, delta * lerp_speed)
	
	var target_freelook_tilt = -deg_to_rad(neck.rotation.y * free_look_angle_amt)
	eyes.rotation.z = current_lean_tilt + target_freelook_tilt

func handle_grabbed_object(delta: float) -> void:
	if grabbed_object:
		var target_pos = grabbed_anchor.global_position
		var distance_vector = target_pos - grabbed_object.global_position
		
		var player_strength = 20.0 
		var required_velocity = (distance_vector * player_strength) / grabbed_object.mass
		grabbed_object.linear_velocity = required_velocity.clamp(Vector3(-50, -50, -50), Vector3(50, 50, 50))
		
		if rotating_object:
			var cam_up = camera_3d.global_transform.basis.y
			var cam_right = camera_3d.global_transform.basis.x
			
			var rot_x = deg_to_rad(object_rotation_input.x * object_rotation_sens)
			var rot_y = deg_to_rad(object_rotation_input.y * object_rotation_sens)
			
			var spin_axis = (cam_up * rot_x) + (cam_right * rot_y)
			grabbed_object.angular_velocity = spin_axis / delta
			
			object_rotation_input = Vector2.ZERO
		else:
			grabbed_object.angular_velocity *= 0.1

func check_bean_proximity():
	if gazunka_beans:
		for bean in gazunka_beans.get_children():
			if is_instance_valid(bean) and not bean.is_queued_for_deletion():
				if global_position.distance_to(bean.global_position) < 1.5:
					try_grabbing(bean)

func hit():
	if !dead:
		dead = true; final_time = time.text 
		stamina_bar.visible = false; time.visible = false; beans_found_label.visible = false
		fade_rect.visible = true; fade_rect.modulate = Color(0.8, 0, 0, 0.6) 
		var tween = create_tween()
		var shake_tween = create_tween().set_parallel(true)
		var shake_duration = 0.5
		var shake_steps = 15
		var step_time = shake_duration / shake_steps

		for i in range(shake_steps):
			var intensity = lerp(0.8, 0.1, float(i) / shake_steps)
			shake_tween.tween_property(camera_3d, "h_offset", randf_range(-intensity, intensity), step_time).set_delay(i * step_time)
			shake_tween.tween_property(camera_3d, "v_offset", randf_range(-intensity, intensity), step_time).set_delay(i * step_time)
		
		shake_tween.tween_property(camera_3d, "fov", 140.0, 0.1).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		shake_tween.tween_property(camera_3d, "fov", 75.0, 0.4).set_delay(0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		shake_tween.tween_property(camera_3d, "rotation_degrees:x", 60.0, 0.4).set_trans(Tween.TRANS_BOUNCE)
		var fall_dir = 65.0 if randf() > 0.5 else -65.0
		shake_tween.tween_property(camera_3d, "rotation_degrees:z", fall_dir, 0.4).set_trans(Tween.TRANS_SINE)
		
		tween.tween_interval(0.15) 
		tween.tween_property(fade_rect, "modulate", Color(0, 0, 0, 1.0), 0.6).set_trans(Tween.TRANS_SINE)
		tween.tween_callback(show_death_ui)

func trigger_screen_shake(intensity: float = 0.1, shake_type: String = "default"):
	var tween = get_tree().create_tween()
	
	tween.tween_property(camera_3d, "h_offset", randf_range(-intensity, intensity), 0.04)
	tween.parallel().tween_property(camera_3d, "v_offset", randf_range(-intensity, intensity), 0.04)
	
	if shake_type == "shotgun":
		var base_fov = camera_3d.fov
		var fov_kick = intensity * 40.0 
		tween.parallel().tween_property(camera_3d, "fov", base_fov + fov_kick, 0.04).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		
		var current_rot_x = camera_3d.rotation.x
		var kick_angle = deg_to_rad(intensity * 25.0) 
		tween.parallel().tween_property(camera_3d, "rotation:x", current_rot_x + kick_angle, 0.04).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)

		tween.chain().tween_property(camera_3d, "h_offset", 0.0, 0.1)
		tween.parallel().tween_property(camera_3d, "v_offset", 0.0, 0.1)
		tween.parallel().tween_property(camera_3d, "fov", base_fov, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.parallel().tween_property(camera_3d, "rotation:x", current_rot_x, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
	else:
		tween.chain().tween_property(camera_3d, "h_offset", 0.0, 0.1)
		tween.parallel().tween_property(camera_3d, "v_offset", 0.0, 0.1)
		
		
func show_death_ui():
	wipe_inventory_on_death()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if hotbar: hotbar.visible = false
	menu_vbox.modulate.a = 0.0
	menu_vbox.visible = true
	menu_vbox.move_to_front()
	var btn_tween = create_tween().set_parallel(true)
	btn_tween.tween_property(menu_vbox, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE)

func bean_found():
	bean_count += 1
	if stamina_bar: stamina_bar.value += bean_stamina_boost
	if enemy_doors and open_noise:
		if bean_count == 1:
			for door in enemy_doors.get_children():
				open_noise.play()
				door.queue_free()
				
	beans_found_label.text = str(bean_count) + '/7'
	trigger_screen_shake()
	play_random_bean_voiceline()
	emit_signal("bean_collected")

func play_random_bean_voiceline():
	if is_exhausted: return
	if bean_count < 7:
		var lines = bean_pickup_voicelines.get_children()
		if lines.size() > 0:
			var random_line = lines.pick_random()
			if random_line is AudioStreamPlayer3D or random_line is AudioStreamPlayer:
				for line in lines:
					if line.playing: line.stop()
				random_line.play()
	else:
		all_seven_beans_voiceline.play()

# --- UI BUTTON CALLBACKS ---
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

func has_loot_to_lose() -> bool:
	if bean_count > 0: return true
	for slot in get_all_ui_slots():
		if slot.item_name != "empty":
			return true
	return false

func _on_cancel_quit_pressed() -> void:
	GlobalStats.play_click()
	quit_confirm_panel.visible = false
	menu_vbox.visible = true

func _on_confirm_quit_pressed() -> void:
	GlobalStats.play_click()
	execute_quit()

func execute_quit() -> void:
	if not dead and (in_heaven or win):
		save_inventory()
	else:
		wipe_inventory_on_death()
		
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_main_menu_pressed() -> void:
	GlobalStats.play_click()
	
	if dead or (in_heaven or win):
		execute_quit()
	elif has_loot_to_lose():
		menu_vbox.visible = false
		quit_confirm_panel.visible = true
	else:
		execute_quit()

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
	GlobalStats.mouse_sens = mouse_sens
	GlobalStats.save_to_disk()

func _on_master_slider_value_changed(value: float) -> void: AudioServer.set_bus_volume_db(master_bus, linear_to_db(value))
func _on_chase_music_slider_value_changed(value: float) -> void: AudioServer.set_bus_volume_db(chase_music_bus, linear_to_db(value))
func _on_effects_slider_value_changed(value: float) -> void: AudioServer.set_bus_volume_db(effects_bus, linear_to_db(value))
func _on_voicelines_slider_value_changed(value: float) -> void: AudioServer.set_bus_volume_db(voicelines_bus, linear_to_db(value))
func _on_ambient_noise_slider_value_changed(value: float) -> void: AudioServer.set_bus_volume_db(ambient_noise_bus, linear_to_db(value))

func _play_hover_sound():
	if button_hover_noise and not button_hover_noise.playing: button_hover_noise.play()

func _on_video_button_pressed() -> void:
	GlobalStats.play_click()
	video_settings.visible = true
	menu_vbox.visible = false

func _on_check_box_toggled(toggled_on: bool) -> void:
	GlobalStats.play_click()
	if toggled_on: minimap.visible = true
	else: minimap.visible = false
		
func spawn_footprint() -> void:
	if footprint_scene and footprint_raycast.is_colliding():
		var footprint = footprint_scene.instantiate()
		get_tree().current_scene.add_child(footprint)
		var hit_pos = footprint_raycast.get_collision_point()
		var hit_normal = footprint_raycast.get_collision_normal()
		var right_direction = global_transform.basis.x.normalized()
		var offset_vector = right_direction * footprint_spacing
		if is_left_foot: offset_vector = -offset_vector
		footprint.global_position = hit_pos + offset_vector
		if hit_normal != Vector3.UP and hit_normal != Vector3.ZERO:
			footprint.look_at(footprint.global_position + hit_normal, Vector3.UP)
			footprint.rotate_object_local(Vector3.RIGHT, deg_to_rad(-90))
		footprint.rotate_y(global_rotation.y)
		if is_left_foot: footprint.scale.x = -1.0
		is_left_foot = !is_left_foot

func spawn_landing_footprints() -> void:
	if footprint_scene and footprint_raycast.is_colliding():
		var hit_pos = footprint_raycast.get_collision_point()
		var hit_normal = footprint_raycast.get_collision_normal()
		var right_direction = global_transform.basis.x.normalized()
		var right_offset = right_direction * footprint_spacing
		var left_offset = -right_direction * footprint_spacing
		
		var left_print = footprint_scene.instantiate()
		get_tree().current_scene.add_child(left_print)
		left_print.global_position = hit_pos + left_offset
		if hit_normal != Vector3.UP and hit_normal != Vector3.ZERO:
			left_print.look_at(left_print.global_position + hit_normal, Vector3.UP)
			left_print.rotate_object_local(Vector3.RIGHT, deg_to_rad(-90))
		left_print.rotate_y(global_rotation.y)
		left_print.scale.x = -1.0
		
		var right_print = footprint_scene.instantiate()
		get_tree().current_scene.add_child(right_print)
		right_print.global_position = hit_pos + right_offset
		if hit_normal != Vector3.UP and hit_normal != Vector3.ZERO:
			right_print.look_at(right_print.global_position + hit_normal, Vector3.UP)
			right_print.rotate_object_local(Vector3.RIGHT, deg_to_rad(-90))
		right_print.rotate_y(global_rotation.y)

func save_final_time() -> void:
	GlobalStats.final_time = total_time
	GlobalStats.final_time_string = time.text
	
	var base_payout = bean_count + bonus_beans
	var final_payout = base_payout
	
	if total_time < 120.0:
		final_payout *= 2
		print("Speedrun bonus achieved! Payout doubled from ", base_payout, " to ", final_payout)
		
	GlobalStats.last_run_profit = final_payout
	GlobalStats.add_to_jar(final_payout)
	
	if total_time < GlobalStats.best_time_float:
		GlobalStats.save_score(total_time, time.text)
		GlobalStats.needs_upload = true

func _on_resume_pressed() -> void:
	if settings_panel.visible or video_settings.visible or controls_settings.visible:
		_on_save_settings_pressed()
		return 
	else:
		GlobalStats.play_click()
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		emit_signal('player_unpaused')
		menu_vbox.visible = false
		settings_panel.visible = false
		paused = false
		if hotbar: hotbar.visible = true

func _on_minimap_checkbox_toggled(_toggled_on: bool) -> void:
	GlobalStats.play_click()

func equip_slot(slot_index: int) -> void:
	if is_switching_weapons or is_reloading: return
	
	var target_slot = slot_index
	if active_slot_index == slot_index: target_slot = -1
	if active_slot_index == -1 and target_slot == -1: return

	is_switching_weapons = true
	
	if active_slot_index != -1:
		var current_item = inventory[active_slot_index]
		if current_item == "shotgun":
			if shotgun_animator.has_animation("put_away"):
				shotgun_animator.play("put_away")
				shotgun_audio.get_node('put_away').play()
				await shotgun_animator.animation_finished
			shotgun_model.visible = false
			
	active_slot_index = target_slot
	update_hotbar_ui()
	
	if active_slot_index != -1:
		var new_item = inventory[active_slot_index]
		if new_item == "shotgun":
			shotgun_ammo = hotbar_slots[active_slot_index].quantity
			is_chambered = (shotgun_ammo > 0)
			
			shotgun_model.visible = true
			if shotgun_animator.has_animation("pull_out"):
				shotgun_animator.play("pull_out")
				shotgun_audio.get_node('pull_out').play()
				
	is_switching_weapons = false

func update_hotbar_ui() -> void:
	for i in range(hotbar_slots.size()):
		var slot_rect = hotbar_slots[i]
		if i == active_slot_index: slot_rect.color = Color(0.8, 0.8, 0.2, 0.8)
		else: slot_rect.color = Color(0, 0, 0, 0.5)

func save_inventory() -> void:
	var hotbar_data = []
	for slot in hotbar_slots:
		if slot.has_method("set_item"):
			hotbar_data.append({"item": slot.item_name, "qty": slot.quantity})

	var grid_data = []
	if inventory_grid:
		for slot in inventory_grid.get_children():
			if slot.has_method("set_item"):
				grid_data.append({"item": slot.item_name, "qty": slot.quantity})

	var save_data = {}
	if FileAccess.file_exists(SAVE_FILE_PATH):
		var save_file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
		var json = JSON.new()
		if json.parse(save_file.get_as_text()) == OK:
			save_data = json.get_data()

	save_data["hotbar"] = hotbar_data
	save_data["grid"] = grid_data
	save_data["shotgun_ammo"] = shotgun_ammo

	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		print("Inventory saved successfully to ", SAVE_FILE_PATH)
	else:
		print("ERROR: Could not open save file to write!")

func load_inventory() -> void:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		print("No save file found. Using default inventory.")
		if inventory_grid and inventory_grid.get_child_count() > 0:
			if inventory_grid.get_child(0).has_method("set_item"):
				inventory_grid.get_child(0).set_item("shotgun_ammo", 12)
		return

	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		var json = JSON.new()
		var parse_result = json.parse(json_string)

		if parse_result == OK:
			var saved_data = json.get_data()

			if saved_data.has("shotgun_ammo"):
				shotgun_ammo = clampi(int(saved_data["shotgun_ammo"]), 0, 4)
				is_chambered = (shotgun_ammo > 0)

			if saved_data.has("hotbar"):
				for i in range(min(saved_data["hotbar"].size(), hotbar_slots.size())):
					var slot_data = saved_data["hotbar"][i]
					if hotbar_slots[i].has_method("set_item"):
						hotbar_slots[i].set_item(slot_data["item"], slot_data["qty"])
					inventory[i] = slot_data["item"]

			if saved_data.has("grid") and inventory_grid:
				var grid_slots = inventory_grid.get_children()
				for i in range(min(saved_data["grid"].size(), grid_slots.size())):
					var slot_data = saved_data["grid"][i]
					if grid_slots[i].has_method("set_item"):
						grid_slots[i].set_item(slot_data["item"], slot_data["qty"])

			print("Inventory loaded successfully!")
		else:
			print("ERROR: Failed to parse save file JSON.")

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if dead or (not in_heaven and not win):
			wipe_inventory_on_death()
		else:
			save_inventory()

func wipe_inventory_on_death() -> void:
	var save_data = {}
	if FileAccess.file_exists(SAVE_FILE_PATH):
		var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			save_data = json.get_data()
			
	save_data["grid"] = []
	save_data["hotbar"] = [{"item": "empty", "qty": 0}, {"item": "empty", "qty": 0}, {"item": "empty", "qty": 0}, {"item": "empty", "qty": 0}]
	save_data["shotgun_ammo"] = 0
	
	var save_file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if save_file:
		save_file.store_string(JSON.stringify(save_data))
		print("Player died. Inventory wiped, stash preserved.")

func update_proximity_distortion(delta: float) -> void:
	if not proximity_distortion or not proximity_distortion.material: return
	
	var target_intensity = 0.0
	
	if is_instance_valid(active_enemy) and not active_enemy.is_ragdolled:
		var distance = global_position.distance_to(active_enemy.global_position)
		
		if distance < 15.0:
			target_intensity = clamp(1.0 - ((distance - 3.0) / 12.0), 0.0, 1.0)
			
	var current_intensity = proximity_distortion.material.get_shader_parameter("intensity")
	if current_intensity == null: current_intensity = 0.0
	
	var new_intensity = move_toward(current_intensity, target_intensity, delta * 1.5)
	proximity_distortion.material.set_shader_parameter("intensity", new_intensity)

func play_inventory_pump_sound() -> void:
	if shotgun_audio and shotgun_audio.has_node('pump'):
		var pump_sfx = shotgun_audio.get_node('pump')
		pump_sfx.pitch_scale = randf_range(0.95, 1.05) 
		pump_sfx.play()

func force_reload_sequence(slot_index: int) -> void:
	if inventory_open:
		toggle_inventory()

	if active_slot_index != slot_index:
		equip_slot(slot_index)
		
		while is_switching_weapons:
			await get_tree().process_frame

	reload_shotgun()


func reward_kill() -> void:
	total_time = max(0.0, total_time - 10.0)
	bonus_beans += 5
	var text_pos = eyes.global_position - (eyes.global_transform.basis.z * 1.5)
	
	# --- THE FIX: Double Payout Text ---
	spawn_floating_text(text_pos, "-10 SECONDS!\n+5 BONUS BEANS!", Color(0.0, 1.0, 0.5))

# --- DOPAMINE UPGRADE: ELASTIC BOUNCING TEXT ---
func spawn_floating_text(pos: Vector3, msg: String = "+1 Gazunka Bean!", color: Color = Color(0.955, 1.0, 0.043, 1.0)):
	var popup = Label3D.new()
	popup.text = msg
	popup.pixel_size = 0.005; popup.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	popup.modulate = color; 
	
	# Start tiny so we can scale it up!
	popup.scale = Vector3.ZERO
	get_tree().current_scene.add_child(popup); 
	popup.global_position = pos
	
	var tween = get_tree().create_tween()
	
	# Bounce scale up to 1.5x, then settle back down to 1.0x
	tween.tween_property(popup, "scale", Vector3(1.5, 1.5, 1.5), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(popup, "scale", Vector3.ONE, 0.2)
	
	# Float upwards and fade out
	tween.parallel().tween_property(popup, "global_position:y", pos.y + 1.5, 1.2).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(popup, "modulate:a", 0.0, 1.2).set_delay(0.5)
	tween.tween_callback(popup.queue_free)
