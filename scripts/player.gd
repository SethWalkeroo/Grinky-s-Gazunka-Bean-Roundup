extends CharacterBody3D
class_name Player

# new hiding logic
@export var active_enemy : Enemy
var is_hidden = false
@onready var shh: AudioStreamPlayer3D = $shh


# --- B-HOP STATE ---
var bhop_jump_buffer: float = 0.0
const BHOP_BUFFER_MAX: float = 0.15 # 150ms window to buffer a jump
const SOURCE_AIR_ACCEL: float = 12.0 # Gives you that smooth air-strafing feel

@onready var gui: CanvasLayer = $neck/head/eyes/CanvasLayer
@onready var wall_torches: Node3D = $"../wall_torches"

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

var rotating_object = false
var bean_count = 0
var win = false
var paused: bool = false
var dead: bool = false
var torch_visible: bool = true
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
@onready var torch_label: Label = $neck/head/eyes/CanvasLayer/torch_label
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
@onready var flashlight: OmniLight3D = $neck/head/eyes/flashlight

@onready var torch: Node3D = $torch
@onready var light_animation: AnimationPlayer = $torch/light_animation
@onready var torchlight: OmniLight3D = $torch/torchlight
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
	
	light_animation.play('init')
	stamina_bar.value = 100
	torch.visible = true
	
	if crosshair:
		crosshair.pivot_offset = crosshair.size / 2
		
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if "heaven.tscn" in get_tree().current_scene.scene_file_path:
		setup_heaven()
	else:
		setup_level()

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
	torch_label.visible = false
	
	if GlobalStats.needs_upload:
		upload_new_best_score()
		
	if win_label:
		torch.visible = false
		torch_visible = false
		var report = "Final Time: " + GlobalStats.final_time_string
		report += "\nPersonal Best: " + GlobalStats.best_time_string
		if GlobalStats.final_time_string == GlobalStats.best_time_string:
			report += "\nNEW PERSONAL RECORD!"
		win_label.text = report
		win_label.visible = true
		win_label.modulate.a = 1.0
		check_global_record()
		
		var tween = get_tree().create_tween()
		tween.tween_interval(5.0)
		tween.tween_property(win_label, "modulate:a", 0.0, 2.0)
		tween.tween_callback(win_label.hide)

func setup_level() -> void:
	exit_door = get_node_or_null("../exit_door")
	gazunka_beans = get_node_or_null("../Gazunka_Beans")
	enemy_doors = get_node_or_null("../enemy_doors")
	open_noise = get_node_or_null("../open_noise")
	if win_label: win_label.visible = false
	start_voiceline.play()

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
		GlobalStats.play_click()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		emit_signal('player_paused')
		menu_vbox.visible = true
		menu_vbox.move_to_front()
		paused = true
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
			return
		
	if dead or paused: return

	if event.is_action_pressed('interact'):
		if grabbed_object:
			if grabbed_object.has_meta("original_mask"):
				grabbed_object.collision_mask = grabbed_object.get_meta("original_mask")
			remove_collision_exception_with(grabbed_object)
			
			grabbed_object = null
			rotating_object = false
		elif object_grabber_shapecast.is_colliding():
			for i in object_grabber_shapecast.get_collision_count():
				var collided = object_grabber_shapecast.get_collider(i)
				if collided is RigidBody3D and !grabbed_object:
					try_grabbing(collided)
					break 

	if event is InputEventMouseMotion:
		if rotating_object and grabbed_object:
			var cam_up = camera_3d.global_transform.basis.y
			var cam_right = camera_3d.global_transform.basis.x
			grabbed_object.global_rotate(cam_up, deg_to_rad(event.relative.x * object_rotation_sens))
			grabbed_object.global_rotate(cam_right, deg_to_rad(event.relative.y * object_rotation_sens))
		else:
			if free_looking:
				neck.rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
				neck.rotation.y = clamp(neck.rotation.y, deg_to_rad(-135), deg_to_rad(135))
			else:
				rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
				head.rotate_x(deg_to_rad(-event.relative.y * mouse_sens))
				head.rotation.x = clamp(head.rotation.x, deg_to_rad(-98), deg_to_rad(98))

	if event is InputEventMouseButton:
		if grabbed_object:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				grab_spring_arm.spring_length = clamp(grab_spring_arm.spring_length + scroll_speed, min_grab_distance, max_grab_distance)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				grab_spring_arm.spring_length = clamp(grab_spring_arm.spring_length - scroll_speed, min_grab_distance, max_grab_distance)
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			rotating_object = event.pressed

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
	grabbed_object.set_meta("original_mask", grabbed_object.collision_mask)
	grabbed_object.collision_mask = 0
	add_collision_exception_with(grabbed_object)
	
	grabbed_object.sleeping = false 
	grab_spring_arm.spring_length = 2.0

func handle_bean_pickup(collided):
	# Always apply a speed boost
	speed_boost_timer = bean_speed_boost_duration

	# Recovery logic if picking up while exhausted
	if is_exhausted:
		is_exhausted = false
		stamina_bar.modulate = Color.WHITE
		if out_of_breath_sound.playing:
			out_of_breath_sound.stop()

	if collided.has_node("pickup_noise"):
		var sfx = collided.get_node("pickup_noise")
		collided.remove_child(sfx)
		get_tree().current_scene.add_child(sfx)
		sfx.global_position = collided.global_position
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
	spawn_floating_text(collided.global_position)
	collided.queue_free()
	if grabbed_object == collided: 
		if grabbed_object.has_meta("original_mask"):
			grabbed_object.collision_mask = grabbed_object.get_meta("original_mask")
		remove_collision_exception_with(grabbed_object)
		grabbed_object = null

func _physics_process(delta: float) -> void:
	if dead or paused: 
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

func update_crosshair(delta: float) -> void:
	if not crosshair: return
	
	var is_interactable = false
	if object_grabber_shapecast.is_colliding():
		for i in object_grabber_shapecast.get_collision_count():
			var collided = object_grabber_shapecast.get_collider(i)
			if collided is RigidBody3D:
				is_interactable = true
				break
				
	var target_color = Color.GREEN if is_interactable else Color.WHITE
	var target_size = Vector2(2, 2) if is_interactable else Vector2(1.0, 1.0)
	
	crosshair.color = lerp(crosshair.color, target_color, delta * 20.0)
	crosshair.size = lerp(crosshair.size, target_size, delta * 20.0)

func update_exhaustion_visuals(delta: float) -> void:
	if not exhaustion_effect: return
	
	# Override: If the player has a speed boost, clear it quickly (0.3 seconds)
	if speed_boost_timer > 0:
		exhaustion_effect.modulate.a = move_toward(exhaustion_effect.modulate.a, 0.0, delta * 3.0)
	elif is_exhausted:
		# Smooth, steady fade-in when they run out of breath (takes 1.0 second)
		exhaustion_effect.modulate.a = move_toward(exhaustion_effect.modulate.a, 1.0, delta * 1.0)
	else:
		# Perfectly smooth, linear fade-out as they catch their breath (takes 2.0 seconds)
		exhaustion_effect.modulate.a = move_toward(exhaustion_effect.modulate.a, 0.0, delta * 0.5)

func handle_timers(delta: float) -> void:
	total_time += delta
	var m = int(total_time / 60.0)
	var s = int(fmod(total_time, 60.0))
	var ms = int(fmod(total_time, 1.0) * 1000.0)
	time.text = "%02d:%02d.%03d" % [m, s, ms] if total_time >= 60.0 else "%02d.%03d" % [s, ms]

	if speed_boost_timer > 0:
		speed_boost_timer -= delta
		if speed_lines:
			speed_lines.modulate.a = lerp(speed_lines.modulate.a, 1.0, delta * 15.0)
	else:
		if speed_lines:
			speed_lines.modulate.a = lerp(speed_lines.modulate.a, 0.0, delta * 5.0)

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
		grabbed_object.sleeping = false
		var final_impulse = throw_dir.normalized() * throw_force * grabbed_object.mass
		var drop_obj = grabbed_object
		
		if drop_obj.has_meta("original_mask"):
			drop_obj.collision_mask = drop_obj.get_meta("original_mask")
		remove_collision_exception_with(drop_obj)
		
		grabbed_object = null
		rotating_object = false
		drop_obj.apply_central_impulse(final_impulse)
		drop_obj.angular_velocity *= 0.1
			
	if Input.is_action_just_pressed('torch') and !in_heaven:
		var main_node = get_parent()
		if !torch_visible:
			if in_heaven or ("torch_count" in main_node and main_node.torch_count > 0): 
				light_animation.play('pull_out')
				await get_tree().process_frame
				torch_visible = true; torch.visible = true
				await light_animation.animation_finished
				light_animation.play('init')
		else:
			light_animation.play('put_away')
			await light_animation.animation_finished
			torch_visible = false; torch.visible = false
			light_animation.stop()

func handle_movement(delta: float) -> void:
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	
	var speed_multiplier = 1.0
	if speed_boost_timer > 0:
		speed_multiplier = bean_speed_boost_amount
	
	if in_heaven:
		stamina_bar.value = 100
	else:
		# --- EXHAUSTION RECOVERY & BLINK ---
		if is_exhausted:
			exhaustion_timer -= delta
			stamina_bar.value = 1.0 
			
			var blink = (sin(Time.get_ticks_msec() * 0.02) + 1.0) / 2.0
			stamina_bar.modulate = Color(1, 0, 0).lerp(Color(1, 0.6, 0.6), blink)
			
			if exhaustion_timer <= 0:
				is_exhausted = false
				stamina_bar.modulate = Color.WHITE
				stamina_bar.value = 0.0
				if out_of_breath_sound.playing:
					out_of_breath_sound.stop()
		
		# --- CONTINUOUS STAMINA DRAIN (SPRINT) ---
		if sprinting and input_dir != Vector2.ZERO and !is_exhausted:
			stamina_bar.value -= stamina_drain_sprint
			stamina_delay_timer = STAMINA_DELAY_MAX 
		else:
			if stamina_delay_timer > 0:
				stamina_delay_timer -= delta 
			elif !is_exhausted: 
				if input_dir == Vector2.ZERO: 
					stamina_bar.value += stamina_regen_idle
				elif crouching or walking: 
					stamina_bar.value += stamina_regen_move

		# --- NEW: CENTRAL EXHAUSTION TRIGGER ---
		if stamina_bar.value <= 0 and !is_exhausted:
			trigger_exhaustion()

	if crouching and ceiling_detection.is_colliding():
		current_speed = crouching_speed * speed_multiplier
		
	if (Input.is_action_pressed('crouch') or sliding) and is_on_floor():
		current_speed = lerp(current_speed, crouching_speed * speed_multiplier, delta * lerp_speed)
		head.position.y = lerp(head.position.y, crouching_depth, delta * lerp_speed)
		standing_collision_shape.disabled = true
		crouching_collision_shape.disabled = false
		if sprinting and input_dir != Vector2.ZERO and !is_exhausted:
			slide_sound.play()
			if not in_heaven: stamina_bar.value -= 10
			sliding = true; mouse_sens = slide_sens
			slide_timer = slide_timer_max; slide_vector = input_dir
			free_looking = true
		walking = false; sprinting = false; crouching = true
	elif !ceiling_detection.is_colliding():
		standing_collision_shape.disabled = false; crouching_collision_shape.disabled = true
		head.position.y = lerp(head.position.y, 0.0, (delta * lerp_speed) * 0.8)
		if Input.is_action_pressed('sprint') and !is_exhausted and (stamina_bar.value != 0 or in_heaven):
			current_speed = lerp(current_speed, sprinting_speed * speed_multiplier, delta * lerp_speed)
			walking = false; sprinting = true; crouching = false
		else:
			current_speed = lerp(current_speed, walking_speed * speed_multiplier, delta * lerp_speed)
			walking = true; sprinting = false; crouching = false

	if not is_on_floor(): 
		velocity += get_gravity() * delta
	
	# --- B-HOP JUMP BUFFERING LOGIC ---
	if Input.is_action_just_pressed("jump"):
		bhop_jump_buffer = BHOP_BUFFER_MAX
		
	if bhop_jump_buffer > 0:
		bhop_jump_buffer -= delta

	if bhop_jump_buffer > 0 and is_on_floor() and !ceiling_detection.is_colliding():
		if is_exhausted and not in_heaven:
			if !out_of_breath_sound.playing:
				out_of_breath_sound.play()
		else:
			if not in_heaven: stamina_bar.value -= 5
			velocity.y = jump_velocity
			sliding = false
			bhop_jump_buffer = 0.0 # Consume the buffer so it doesn't double-trigger
			jump_sound.play()
			animation_player.play('jumping')

	if is_on_floor() and last_velocity.y < 0.0:
		animation_player.play('landing')
		footsteps.play()
		spawn_landing_footprints()

	# --- DIRECTION & MOMENTUM ---
	var target_dir = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if is_on_floor():
		if in_heaven and bhop_jump_buffer > 0:
			# Prevent ground friction from killing momentum if a jump is buffered
			direction = target_dir if target_dir != Vector3.ZERO else direction
		else:
			direction = lerp(direction, target_dir, delta * lerp_speed)
	else:
		if in_heaven and target_dir != Vector3.ZERO:
			# Apply "Source-like" air acceleration for strafing
			direction = lerp(direction, target_dir, delta * SOURCE_AIR_ACCEL)
		elif target_dir != Vector3.ZERO:
			# Standard air control for normal levels
			direction = lerp(direction, target_dir, delta * air_lerp_speed)
		
	if sliding:
		direction = (transform.basis * Vector3(slide_vector.x, 0, slide_vector.y)).normalized()
		current_speed = (slide_timer + 0.1) * slide_speed * speed_multiplier
		
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		if in_heaven and not is_on_floor():
			# Don't apply drag in the air while in heaven, preserving velocity
			pass
		else:
			# Standard friction/drag
			velocity.x = move_toward(velocity.x, 0, current_speed)
			velocity.z = move_toward(velocity.z, 0, current_speed)
		
	last_velocity = velocity
	move_and_slide()

# Helper function to trigger the penalty state
func trigger_exhaustion():
	is_exhausted = true
	exhaustion_timer = exhaustion_penalty_duration
	if !out_of_breath_sound.playing:
		out_of_breath_sound.play()
	
	# Stop ongoing voicelines
	var lines = bean_pickup_voicelines.get_children()
	for line in lines:
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
	
	if Input.is_action_pressed('freelook') or sliding: 
		free_looking = true
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
		var required_velocity = (target_pos - grabbed_object.global_position) / delta
		grabbed_object.linear_velocity = required_velocity.clamp(Vector3(-50, -50, -50), Vector3(50, 50, 50))
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
		
		var main_node = get_parent()
		if "torch_label" in main_node and main_node.torch_label:
			main_node.torch_label.visible = false

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

func spawn_floating_text(pos: Vector3):
	var popup = Label3D.new()
	popup.text = "+1 Gazunka Bean!"
	popup.pixel_size = 0.005; popup.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	popup.modulate = Color(0.955, 1.0, 0.043, 1.0); get_tree().current_scene.add_child(popup); popup.global_position = pos
	var tween = get_tree().create_tween()
	tween.tween_property(popup, "global_position:y", pos.y + 1.5, 1.2).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(popup, "modulate:a", 0.0, 1.2)
	tween.tween_callback(popup.queue_free)

func trigger_screen_shake(intensity: float = 0.1):
	var tween = get_tree().create_tween()
	tween.tween_property(camera_3d, "h_offset", randf_range(-intensity, intensity), 0.04)
	tween.parallel().tween_property(camera_3d, "v_offset", randf_range(-intensity, intensity), 0.04)
	tween.tween_property(camera_3d, "h_offset", 0.0, 0.1)
	tween.parallel().tween_property(camera_3d, "v_offset", 0.0, 0.1)

func show_death_ui():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	menu_vbox.modulate.a = 0.0
	menu_vbox.visible = true
	menu_vbox.move_to_front()
	var btn_tween = create_tween().set_parallel(true)
	btn_tween.tween_property(menu_vbox, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE)

func bean_found():
	bean_count += 1
	if stamina_bar:
		stamina_bar.value += bean_stamina_boost
	
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
	if is_exhausted:
		return

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
	if "heaven.tscn" in get_tree().current_scene.scene_file_path:
		get_tree().change_scene_to_file("res://scenes/main.tscn")
	else:
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

func _on_main_menu_pressed() -> void:
	GlobalStats.play_click()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

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

func _on_master_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(master_bus, linear_to_db(value))

func _on_chase_music_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(chase_music_bus, linear_to_db(value))

func _on_effects_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(effects_bus, linear_to_db(value))

func _on_voicelines_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(voicelines_bus, linear_to_db(value))

func _on_ambient_noise_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(ambient_noise_bus, linear_to_db(value))

func _play_hover_sound():
	if button_hover_noise and not button_hover_noise.playing:
		button_hover_noise.play()

func _on_video_button_pressed() -> void:
	GlobalStats.play_click()
	video_settings.visible = true
	menu_vbox.visible = false

func _on_check_box_toggled(toggled_on: bool) -> void:
	GlobalStats.play_click()
	if toggled_on:
		minimap.visible = true
	else:
		minimap.visible = false
		
func spawn_footprint() -> void:
	if footprint_scene and footprint_raycast.is_colliding():
		var footprint = footprint_scene.instantiate()
		get_tree().current_scene.add_child(footprint)
		
		var hit_pos = footprint_raycast.get_collision_point()
		var hit_normal = footprint_raycast.get_collision_normal()
		var right_direction = global_transform.basis.x.normalized()
		var offset_vector = right_direction * footprint_spacing
		
		if is_left_foot:
			offset_vector = -offset_vector
		
		footprint.global_position = hit_pos + offset_vector
		
		if hit_normal != Vector3.UP and hit_normal != Vector3.ZERO:
			footprint.look_at(footprint.global_position + hit_normal, Vector3.UP)
			footprint.rotate_object_local(Vector3.RIGHT, deg_to_rad(-90))
			
		footprint.rotate_y(global_rotation.y)
		if is_left_foot:
			footprint.scale.x = -1.0
		is_left_foot = !is_left_foot

func spawn_landing_footprints() -> void:
	if footprint_scene and footprint_raycast.is_colliding():
		var hit_pos = footprint_raycast.get_collision_point()
		var hit_normal = footprint_raycast.get_collision_normal()
		var right_direction = global_transform.basis.x.normalized()
		var right_offset = right_direction * footprint_spacing
		var left_offset = -right_direction * footprint_spacing
		
		# Left Foot
		var left_print = footprint_scene.instantiate()
		get_tree().current_scene.add_child(left_print)
		left_print.global_position = hit_pos + left_offset
		if hit_normal != Vector3.UP and hit_normal != Vector3.ZERO:
			left_print.look_at(left_print.global_position + hit_normal, Vector3.UP)
			left_print.rotate_object_local(Vector3.RIGHT, deg_to_rad(-90))
		left_print.rotate_y(global_rotation.y)
		left_print.scale.x = -1.0
		
		# Right Foot
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
	
	# Deposit this run's beans into the permanent jar
	GlobalStats.add_to_jar(bean_count)
	
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


func _on_minimap_checkbox_toggled(toggled_on: bool) -> void:
	GlobalStats.play_click()
