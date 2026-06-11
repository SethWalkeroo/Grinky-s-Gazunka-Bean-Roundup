extends CharacterBody3D
class_name Player

@onready var sens_slider: HSlider = $neck/head/eyes/CanvasLayer/video_settings/VBoxContainer/HBoxContainer5/sens_slider
@onready var sens_label: Label = $neck/head/eyes/CanvasLayer/video_settings/VBoxContainer/HBoxContainer5/sens_slider/sens_label

@onready var death_noises: Node3D = $death_noises
@onready var hit_noises: Node3D = $hit_noises

#zooming
@export var zoom_fov = 40.0
var default_base_fov = 77.7
var is_zooming = false

# --- WATER PHYSICS ---
@export var ocean_base_height: float = 0.0 # Set this to the exact Y position of your Ocean node!
var is_underwater: bool = false
var water_surface_height: float = 0.0 # Where the top of the water is
var bobbing_timer: float = 0.0

#blackout run
@export var blackout_run_chance = 0.333

# --- PANIC ATTACK VARIABLES ---
var panic_fov_modifier: float = 0.0
var is_panicking: bool = false

@onready var gui: PlayerGUI = $neck/head/eyes/CanvasLayer
@onready var compass_arrow: Node3D = $neck/head/eyes/Camera3D/compass_arrow
const INVENTORY_SAVE_PATH = "user://player_inventory.json"
@onready var blackout_voiceline: AudioStreamPlayer3D = $blackout_voiceline

#nightvision
@onready var nv_sound: AudioStreamPlayer = $nightvision_sound
@onready var nv_off_sound: AudioStreamPlayer = $nightvision_off_sound
@onready var nv_on_sound: AudioStreamPlayer = $nightvision_on_sound
@onready var nv_light: SpotLight3D = $neck/head/eyes/Camera3D/nv_light
var night_vision_active: bool = false

#flashlight
@onready var flashlight: SpotLight3D = $neck/head/eyes/Camera3D/flashlight
var flashlight_active: bool = false
var is_blackout_run: bool = false
var flashlight_battery: float = 100.0
var is_cranking: bool = false
var ignore_camera_pan: bool = false

@export var bean_wisp_scene: PackedScene
@export var wisp_max_cooldown: float = 15.0
var bean_sense_cooldown: float = 0.0

# --- NEW COD HEALTH ---
var max_health: int = 2
var current_health: int = max_health
var regen_timer: float = 0.0
var time_before_regen: float = 4.0

# --- APEX SLIDE VARIABLES ---
var is_sliding: bool = false
var slide_boost_available: bool = true
var slide_cooldown_timer: float = 0.0 
@export var slide_cooldown: float = 1.2 
@export var slide_friction: float = 0.777
@export var slope_acceleration: float = 18.0 
@onready var slide_loop_sound: AudioStreamPlayer3D = $slide_loop_sound

# --- NEW DYNAMIC MOMENTUM VARIABLES ---
@export var sprint_acceleration: float = 7.777 
@export var slide_boost_multiplier: float = 0.85 
var object_rotation_input: Vector2 = Vector2.ZERO

@export var active_enemy : Enemy
var is_hidden = false
@onready var shh: AudioStreamPlayer3D = $shh

#fps rig
@onready var view_model_camera: Camera3D = $neck/head/eyes/Camera3D/SubViewportContainer/SubViewport/view_model_camera
@onready var shotgun_audio = view_model_camera.get_node('shotgun_rig/shotgun/shotgun_audio')
@export var impact_scene: PackedScene

# --- INVENTORY & HOTBAR STATE ---
const SAVE_FILE_PATH = "user://player_inventory.json"
var inventory = ["shotgun", "empty", "empty", "empty"]
var active_slot_index: int = -1 
var is_switching_weapons: bool = false
var inventory_open: bool = false

var shotgun_ammo: int = 4
var is_reloading: bool = false
var is_chambered: bool = true
var cancel_reload: bool = false

@onready var shotgun_model: Node3D = view_model_camera.get_node('shotgun_rig')
@onready var shotgun_animator: AnimationPlayer = view_model_camera.get_node('shotgun_rig/shotgun/AnimationPlayer')

# --- B-HOP STATE ---
var bhop_jump_buffer: float = 0.0
const BHOP_BUFFER_MAX: float = 0.15 
const SOURCE_AIR_ACCEL: float = 12.0 
var jump_cooldown: float = 0.0

@onready var wall_torches: Node3D = get_node_or_null("../wall_torches")
@onready var button_hover_noise: AudioStreamPlayer = $button_hover_noise
@onready var button_click_noise: AudioStreamPlayer = $button_click_noise
@onready var exit_warning_voiceline: AudioStreamPlayer3D = $exit_warning_voiceline
@onready var all_seven_beans_voiceline: AudioStreamPlayer3D = $all_seven_beans_voiceline
@onready var out_of_breath_sound: AudioStreamPlayer3D = $out_of_breath_sound
@onready var heartbeat_sound: AudioStreamPlayer = $heartbeat_sound

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
@export var bean_stamina_boost: float = 25.0 
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
var default_mouse_sens: float = GlobalStats.mouse_sens / 4.0
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
var timer_started: bool = false
var grabbed_object = null
var final_time: String = "" 

@export var footprint_scene: PackedScene
@export var footprint_spacing: float = 0.15
@onready var footprint_raycast: RayCast3D = $footprint_raycast
var is_left_foot: bool = true 

@onready var grabbed_anchor: Marker3D = $neck/head/eyes/SpringArm3D/GrabbedAnchor
@onready var object_grabber_shapecast: ShapeCast3D = $neck/head/eyes/object_grabber_shapecast
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

#footstep audio
@onready var footsteps: AudioStreamPlayer3D = $footstep_audio/footsteps
@onready var grass_footsteps: AudioStreamPlayer3D = $footstep_audio/grass_footsteps

var exit_door: Area3D = null
var gazunka_beans: Node3D = null
@onready var icon_component: Node3D = $IconComponent

# --- OPTIMIZATION CACHE ---
var player_rid: RID 
var self_exclude_array: Array[RID]


# A quick helper function to update the text display
func update_sens_label(val: float) -> void:
	if sens_label:
		# snaps the value to 1 decimal place so it looks clean (e.g. "Sens: 1.5")
		sens_label.text = str(snapped(val, 0.1))

func _ready() -> void:
	
	sens_slider.value = GlobalStats.mouse_sens
	update_sens_label(GlobalStats.mouse_sens)
	
	
	icon_component.get_node('icon_sprite').pixel_size = 0.0003
	
	# Cache our RID heavily used in raycasts
	player_rid = self.get_rid()
	self_exclude_array = [player_rid]
	
	if compass_arrow:
		compass_arrow.visible = false
	gui.setup(self)
	
	$neck/head/eyes/Camera3D/SubViewportContainer/SubViewport.size = DisplayServer.window_get_size()

	grab_spring_arm.add_excluded_object(self)
	object_grabber_shapecast.add_exception(self)
	footprint_raycast.add_exception(self)
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if "heaven.tscn" in get_tree().current_scene.scene_file_path:
		setup_heaven()
	else:
		setup_level()
		
	if shotgun_model: shotgun_model.visible = false
		
	load_inventory()
	gui.update_hotbar(active_slot_index)
	refresh_all_slots()

func setup_heaven() -> void:
	gui.hide_hud_for_heaven()
	in_heaven = true
	
	if GlobalStats.needs_upload:
		upload_new_best_score()
		
	if not GlobalStats.came_from_main_menu:
		if gui.win_label:
			var report = "Final Time: " + GlobalStats.final_time_string
			report += "\nPersonal Best: " + GlobalStats.best_time_string
			if GlobalStats.final_time_string == GlobalStats.best_time_string:
				report += "\nNEW PERSONAL RECORD!"
			report += "\n\nTotal Profit: +" + str(GlobalStats.last_run_profit) + " Beans!"
			if float(GlobalStats.final_time) < 120.0:
				report += " (2x Speed Bonus!)"
				
			# THE FIX: Send the base report to the checker first!
			check_global_record(report)
	else:
		if gui.win_label: gui.win_label.visible = false

func setup_level() -> void:
	# Wait exactly one frame so the torches have time to set up their @onready variables!
	await get_tree().process_frame
	
	# --- THE FIX: RESET LIGHTING BEFORE THE DICE ROLL ---
	# Find the environment and force it back to default settings, curing the map of any previous blackouts!
	var environments = get_tree().current_scene.find_children("*", "WorldEnvironment", true, false)
	# --- THE NEW WEB / COMPATIBILITY CHECK ---
	if environments.size() > 0:
		var world_env = environments[0]
		# DESKTOP MODE: Ensure normal AAA lighting is reset
		if world_env.environment:
			world_env.environment.ambient_light_energy = 0
			world_env.environment.background_energy_multiplier = 0
			world_env.environment.fog_light_energy = 0.015
			world_env.environment.fog_light_color = Color('ffefc5')

	# --- LIGHT SOURCE CHECK ---
	var has_light = get_total_item_count("flashlight") > 0 or get_total_item_count("nightvision") > 0

	# --- THE BLACKOUT EVENT ---
	# A 5% chance (0.05) that the map loads in pitch black!
	if has_light and randf() <= blackout_run_chance:
		print("Bravo Six, going dark...")
		is_blackout_run = true
		
		# 1. Kill the physical torches (but leave the wooden sticks!)
		if wall_torches:
			for torch in wall_torches.get_children():
				torch.extinguish_torch()
				
		# 2. Kill the Ambient Light / Skybox
		if environments.size() > 0:
			var world_env = environments[0]
			if world_env.environment:
				# Crush the shadow brightness to pitch black
				world_env.environment.ambient_light_energy = 0.0
				world_env.environment.background_energy_multiplier = 0.0
				world_env.environment.fog_light_energy = 0
				
	exit_door = get_node_or_null("../exit_door")
	gazunka_beans = get_node_or_null("../Gazunka_Beans")
	if gui.win_label: gui.win_label.visible = false
	if is_blackout_run:
		blackout_voiceline.play()
	else:
		start_voiceline.play()
	
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

func check_global_record(base_report: String):
	var final_report = base_report
	var sw_result = await SilentWolf.Scores.get_scores(10, "main").sw_get_scores_complete
	var scores = sw_result.scores
	
	if scores.size() > 0:
		var fastest_time = float(scores[0].score)
		for score_data in scores:
			var current_score_in_list = float(score_data.score)
			if current_score_in_list < fastest_time:
				fastest_time = current_score_in_list
		
		var my_time = GlobalStats.final_time
		if float(my_time) < fastest_time - 0.001:
			final_report += "\nNEW GLOBAL RECORD!"
			gui.win_label.add_theme_color_override("font_color", Color.CHARTREUSE)
	else:
		final_report += "\nNEW GLOBAL RECORD!"
		gui.win_label.add_theme_color_override("font_color", Color.CHARTREUSE)
		
	# Now that we know exactly what the text should be, type it all out!
	if gui.has_method("play_win_intro"):
		gui.play_win_intro(final_report)

func _input(event: InputEvent) -> void:
	
	if event.is_action_pressed('zoom') and not dead and not paused and not inventory_open and not grabbed_object:
		is_zooming = true
	elif event.is_action_released('zoom'):
		is_zooming = false
	
	if event.is_action_pressed("screenshot"):
		GlobalStats.play_click()
		await get_tree().process_frame
		var capture = get_viewport().get_texture().get_image()
		var sys_time = Time.get_datetime_string_from_system().replace(":", "_")
		var filename = "user://screenshot_" + sys_time + ".png"
		capture.save_png(filename)
		gui.show_screenshot_notification(filename)
		print("Screenshot saved to: ", ProjectSettings.globalize_path(filename))
		
	# --- FREEZE INPUTS WHILE CRANKING & ALLOW EXIT ---
	if is_cranking:
		if event.is_action_pressed("flashlight") or event.is_action_pressed("reload") or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT):
			stop_crank_minigame()
		elif event is InputEventKey and event.keycode == KEY_ESCAPE and event.is_pressed():
			stop_crank_minigame()
			get_viewport().set_input_as_handled()
		return 

	# --- SAFELY GET THE EQUIPPED ITEM ---
	var held_item = ""
	if active_slot_index != -1 and inventory.size() > active_slot_index:
		held_item = inventory[active_slot_index]

	# --- THE RELOAD / CRANK TRIGGER ---
	if event.is_action_pressed("reload") and not dead and not paused:
		if held_item == "flashlight":
			start_crank_minigame()
		elif held_item == "shotgun":
			reload_shotgun() 

	# --- FLASHLIGHT (REQUIRES EQUIPPED ITEM) ---
	if event.is_action_pressed("flashlight") and not dead and not paused:
		if held_item == "flashlight":
			if flashlight_battery > 0.0:
				flashlight_active = !flashlight_active
				if flashlight: flashlight.visible = flashlight_active
				if flashlight.visible:
					nv_on_sound.play()
				else:
					nv_off_sound.play()
				
				# Shut off NVGs if they blind themselves
				if flashlight_active and night_vision_active:
					night_vision_active = false
					if nv_light: nv_light.visible = false
					var nv_overlay = gui.get_node_or_null("night_vision_overlay")
					if nv_overlay: nv_overlay.visible = false
					if nv_off_sound: nv_off_sound.play()
			else:
				start_crank_minigame()
	
	# --- NIGHT VISION (REQUIRES EQUIPPED TO FACE) ---
	if event.is_action_pressed("nightvision") and not dead and not paused:
		
		# THE FIX: Check the dedicated equipment slot instead of the whole inventory!
		if gui.nvg_slot and gui.nvg_slot.item_name == "nightvision":
			night_vision_active = !night_vision_active
			
			if nv_light: nv_light.visible = night_vision_active
			
			if night_vision_active:
				nv_on_sound.play()
				if nv_sound: nv_sound.play()
				if flashlight_active: 
					flashlight_active = false
					if flashlight: flashlight.visible = false
			else:
				if nv_off_sound: nv_off_sound.play()
			
			var nv_overlay = gui.get_node_or_null("night_vision_overlay")
			if nv_overlay:
				nv_overlay.visible = night_vision_active
				if night_vision_active and nv_overlay.material:
					var mat = nv_overlay.material as ShaderMaterial
					mat.set_shader_parameter("brightness_multiplier", 25.0)
					var tween = create_tween()
					tween.tween_property(mat, "shader_parameter/brightness_multiplier", 2.5, 0.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		else:
			# Play click if the slot is empty!
			shotgun_audio.get_node('click').play()
			
	if gui.handle_input(event):
		get_viewport().set_input_as_handled()
		return
		
	if event.is_action_pressed('beansense') and bean_sense_cooldown <= 0.0 and not dead:
		trigger_bean_sense()
	
	if event.is_action_pressed('pause') and !paused and !dead:
		if inventory_open: toggle_inventory()
		GlobalStats.play_click()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		emit_signal('player_paused')
		gui.menu_vbox.visible = true
		gui.menu_vbox.move_to_front()
		paused = true
		return
	elif event.is_action_pressed('pause') and paused and !dead:
		if gui.is_in_sub_menus():
			gui._on_save_settings_pressed()
			return 
		else:
			unpause_game()
			return
			
	if event is InputEventKey and event.is_pressed() and not event.is_echo() and not paused and not dead:
		if event.keycode == KEY_TAB:
			GlobalStats.play_click()
			toggle_inventory()
		
	if dead or paused or inventory_open: return

	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_1: equip_slot(0)
		elif event.keycode == KEY_2: equip_slot(1)
		elif event.keycode == KEY_3: equip_slot(2)
		elif event.keycode == KEY_4: equip_slot(3)
		elif event.keycode == KEY_R: reload_shotgun()

	if event.is_action_pressed('interact'):
		if active_slot_index != -1 and inventory[active_slot_index] == "shotgun":
			if is_reloading: cancel_reload = true
			else: fire_shotgun()
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
						query.exclude = [player_rid, collided.get_rid()]
						query.collision_mask = 1 
						var hit_wall = space_state.intersect_ray(query)
						if not hit_wall:
							try_grabbing(collided)
							break

	if event is InputEventMouseMotion:
		if ignore_camera_pan: return
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

func toggle_inventory() -> void:
	inventory_open = !inventory_open
	
	# THE FIX: Tell Godot to actually show/hide the mouse!
	if inventory_open:
		gui.hotbar.visible = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		gui.hotbar.visible = GlobalStats.hotbar_on
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		
	# Tell the GUI script to show/hide the menus
	gui.toggle_inventory(inventory_open)

func unpause_game() -> void:
	GlobalStats.play_click()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	emit_signal('player_unpaused')
	gui.menu_vbox.visible = false
	gui.settings_panel.visible = false
	paused = false

func fire_shotgun() -> void:
	if is_switching_weapons or is_reloading: return
	
	# THE FIX: Prevents firing if you are currently shoving!
	if shotgun_animator.is_playing() and (shotgun_animator.current_animation == "fire" or shotgun_animator.current_animation == "pump" or shotgun_animator.current_animation == "shove"): return
		
	if shotgun_ammo > 0:
		shotgun_ammo -= 1
		gui.hotbar_slots[active_slot_index].quantity = shotgun_ammo
		var flash = view_model_camera.get_node_or_null('shotgun_rig/shotgun/muzzle_flash')
		if flash:
			flash.visible = true
			var flash_timer = get_tree().create_timer(0.05)
			flash_timer.timeout.connect(func(): flash.visible = false)
			
		trigger_screen_shake(0.2, "shotgun")
		
		# Tell every enemy on the map to investigate this loud boom!
		var shotgun_loudness_sq = 50.0 * 50.0 # Squared distance for optimization
		for enemy in get_tree().get_nodes_in_group("enemy"):
			if is_instance_valid(enemy) and enemy.has_method("investigate_sound"):
				if global_position.distance_squared_to(enemy.global_position) <= shotgun_loudness_sq:
					enemy.investigate_sound(global_position, 50.0)
		
		var knockback_dir = camera_3d.global_transform.basis.z.normalized()
		knockback_dir += Vector3(0, 0.2, 0) 
		velocity += knockback_dir * 4.0 
		
		var space_state = get_world_3d().direct_space_state
		var origin = camera_3d.global_position
		var pellets = 8          
		var spread_amount = 0.08 
		var range_distance = 50.0 
		
		var shot_excludes = [player_rid]
		if is_instance_valid(gazunka_beans):
			for bean in gazunka_beans.get_children():
				if is_instance_valid(bean) and bean is CollisionObject3D:
					shot_excludes.append(bean.get_rid())
					
		# OPTIMIZATION: Create parameters ONCE, only update the end point inside the loop
		var query = PhysicsRayQueryParameters3D.create(origin, origin) 
		query.exclude = shot_excludes 
		
		for i in range(pellets):
			var spread_offset = Vector3(
				randf_range(-spread_amount, spread_amount), 
				randf_range(-spread_amount, spread_amount), 
				randf_range(-spread_amount, spread_amount)
			)
			
			var pellet_direction = (-camera_3d.global_transform.basis.z + spread_offset).normalized()
			var end_point = origin + (pellet_direction * range_distance)
			
			# Reuse the physics query object
			query.to = end_point 
			var result = space_state.intersect_ray(query)
			
			if result and result.collider is Enemy:
				var pierce_query = PhysicsRayQueryParameters3D.create(result.position, end_point)
				var pierce_excludes = shot_excludes.duplicate()
				pierce_excludes.append(result.collider.get_rid()) 
				pierce_query.exclude = pierce_excludes
				var bone_result = space_state.intersect_ray(pierce_query)
				if bone_result and bone_result.collider is PhysicalBone3D:
					result = bone_result
			
			if result:
				if impact_scene:
					var impact = impact_scene.instantiate()
					result.collider.add_child(impact)
					var final_pos = result.position
					var hit_normal = result.normal
					if result.collider is Enemy: final_pos -= (hit_normal * 0.4)
						
					impact.global_position = final_pos
					if hit_normal != Vector3.UP and hit_normal != Vector3.DOWN:
						impact.look_at(final_pos + hit_normal, Vector3.UP)
					elif hit_normal == Vector3.UP:
						impact.rotation_degrees.x = 90
					elif hit_normal == Vector3.DOWN:
						impact.rotation_degrees.x = -90
						
					var surface_type = "default"
					var hit_node = result.collider
					
					if hit_node is GridMap:
						if hit_normal.is_equal_approx(Vector3.UP): surface_type = "wood"
						else: surface_type = "stone" 
					elif hit_node.is_in_group("wood"): surface_type = "wood"
					elif hit_node.is_in_group("metal"): surface_type = "metal"
					elif hit_node.is_in_group("flesh") or hit_node is Enemy or hit_node is PhysicalBone3D:
						surface_type = "flesh"
					
					if impact.has_method("play_impact"): impact.play_impact(surface_type)
						
				var hit_node = result.collider
				var is_headshot = false

				if hit_node is PhysicalBone3D and "head" in hit_node.name.to_lower():
					is_headshot = true
					var temp_node = hit_node
					while temp_node and not temp_node is Enemy:
						temp_node = temp_node.get_parent()
					if temp_node is Enemy: hit_node = temp_node

				elif hit_node is Enemy:
					var local_y = result.position.y - hit_node.global_position.y
					if local_y > 1.6: 
						is_headshot = true
						
				if hit_node and hit_node.has_method("take_damage"):
					var hit_distance = origin.distance_to(result.position)
					var pellet_damage = remap(hit_distance, 0.0, range_distance, 15.0, 2.0)
					if is_headshot: pellet_damage *= 2.5
					var final_damage = int(clamp(pellet_damage, 2.0, 50.0))
					hit_node.take_damage(final_damage, result.position, is_headshot)
					
				if result.collider is RigidBody3D or result.collider is PhysicalBone3D:
					if result.collider is RigidBody3D:
						result.collider.freeze = false
						result.collider.gravity_scale = 1.0 
						result.collider.sleeping = false 
					var push_dir = -camera_3d.global_transform.basis.z.normalized()
					result.collider.apply_impulse(push_dir * 50.0, result.position - result.collider.global_position)

		# --- THE ASYNC FIX ---
		# 1. Instantly unchamber the gun the moment the shell is fired
		is_chambered = false

		if shotgun_animator.has_animation("fire"):
			shotgun_animator.play("fire")
			shotgun_audio.get_node('fire').play()
			await shotgun_animator.animation_finished
			
		# 2. Check if the player interrupted the fire animation to reload!
		if is_reloading or is_switching_weapons:
			refresh_all_slots()
			return
			
		# 3. Only play the pump if we haven't been interrupted
		if shotgun_animator.has_animation("pump"):
			shotgun_animator.play("pump")
			shotgun_audio.get_node('pump').play()
			await shotgun_animator.animation_finished
			
		# 4. Check one last time in case they interrupted the pump animation itself!
		if is_reloading or is_switching_weapons:
			refresh_all_slots()
			return
			
		# 5. If we survived the whole sequence without being interrupted, chamber the next round!
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
	if shotgun_animator.is_playing() and shotgun_animator.current_animation == "shove": return
	
	if shotgun_ammo >= 4: return 
	
	var ammo_available = get_total_item_count("shotgun_ammo")
	if ammo_available <= 0: return
		
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
			
		shotgun_ammo += 1
		gui.hotbar_slots[active_slot_index].quantity = shotgun_ammo
		consume_item("shotgun_ammo", 1) 
		refresh_all_slots()
		
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

func get_all_ui_slots() -> Array:
	var all = []
	all.append_array(gui.hotbar_slots)
	if gui.inventory_grid:
		all.append_array(gui.inventory_grid.get_children())
	if gui.nvg_slot:
		all.append(gui.nvg_slot)
	return all

func get_total_item_count(target_item: String) -> int:
	var total = 0
	for slot in get_all_ui_slots():
		if slot.item_name == target_item: total += slot.quantity
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
		if slot.has_method("refresh_label"): slot.refresh_label()

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
	if "sleeping" in grabbed_object: grabbed_object.sleeping = false 
	grab_spring_arm.spring_length = 2.0

func handle_bean_pickup(collided):
	speed_boost_timer = bean_speed_boost_duration
	if is_exhausted:
		is_exhausted = false
		gui.stamina_bar.modulate = Color.WHITE
		if out_of_breath_sound.playing: out_of_breath_sound.stop()

	if collided.has_node("pickup_noise"):
		var sfx = collided.get_node("pickup_noise")
		collided.remove_child(sfx)
		get_tree().current_scene.add_child(sfx)
		sfx.global_position = collided.global_position
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
		if grabbed_object.has_meta("original_mask"): grabbed_object.collision_mask = grabbed_object.get_meta("original_mask")
		remove_collision_exception_with(grabbed_object)
		grabbed_object = null

func _physics_process(delta: float) -> void:
	$neck/head/eyes/Camera3D/SubViewportContainer/SubViewport/view_model_camera.global_transform = camera_3d.global_transform
	
	# --- BEAN SENSE COOLDOWN ---
	if bean_sense_cooldown > 0.0:
		bean_sense_cooldown -= delta
		# Send the sweeping UI the current time, and the max time (5 seconds)
		gui.update_wisp_cooldown(bean_sense_cooldown, wisp_max_cooldown)
	else:
		bean_sense_cooldown = 0.0
		# Tell the UI it's ready!
		gui.update_wisp_cooldown(0.0, wisp_max_cooldown)

	if not dead and not paused: 
		if current_health < max_health:
			regen_timer -= delta
			if regen_timer <= 0.0:
				current_health = max_health
				if heartbeat_sound and heartbeat_sound.playing:
					heartbeat_sound.stop()
		gui.update_vignette(current_health, max_health, delta)

	if dead or paused or inventory_open: 
		if dead:
			final_time = gui.time.text
			GlobalStats.final_time = total_time 
			GlobalStats.final_time_string = gui.time.text
			timer.stop()
		return

	update_crosshair(delta)
	
	if timer_started:
		total_time += delta
	gui.update_timers(total_time, speed_boost_timer, bean_count, delta, rainbow_speed)
	if speed_boost_timer > 0: speed_boost_timer -= delta
		
	handle_interaction()
	handle_movement(delta)
	handle_camera_and_bobbing(delta)
	handle_grabbed_object(delta)
	check_bean_proximity()
	
	# --- THE VICTORY COMPASS ---
	# THE FIX: Added "and not dead" so it doesn't pop back up while you are dying!
	if bean_count >= 7 and is_instance_valid(exit_door) and compass_arrow and not dead:
		if not compass_arrow.visible:
			compass_arrow.visible = true
			
			compass_arrow.scale = Vector3.ZERO
			var tween = get_tree().create_tween()
			tween.tween_property(compass_arrow, "scale", Vector3.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			
		# Make the arrow point at the door
		var target_pos = exit_door.global_position
		var arrow_pos = compass_arrow.global_position
		var look_pos = Vector3(target_pos.x, arrow_pos.y, target_pos.z) 
		
		# Optimization: Squared distance logic check
		if arrow_pos.distance_squared_to(look_pos) > 0.01:
			var target_transform = compass_arrow.global_transform.looking_at(look_pos, Vector3.UP)
			compass_arrow.global_transform = compass_arrow.global_transform.interpolate_with(target_transform, delta * 8.0)
			
		# --- UPGRADE: SYNCHRONIZED BOB AND FADE ---
		# 1. Calculate the wave exactly ONCE so the timing is permanently locked together
		var sync_wave = sin(total_time * 4.0) 
		
		# 2. Apply the wave to the physical bobbing
		compass_arrow.position.y = 0.3 + (sync_wave * 0.015)

		# 3. Apply the exact same wave to the transparency
		if compass_arrow.get_child_count() > 0:
			var arrow_mesh = compass_arrow.get_child(0)
			if arrow_mesh is GeometryInstance3D:
				# Convert the wave (which goes from -1 to 1) into a 0.0 to 1.0 slider
				var fade_slider = (sync_wave + 1.0) / 2.0
				
				# When sync_wave is 1 (Arrow is UP), fade_slider is 1.0 (Fades out!)
				# When sync_wave is -1 (Arrow is DOWN), fade_slider is 0.0 (Fades in!)
				arrow_mesh.transparency = fade_slider * 0.95
	
	# --- CRAPPY FLASHLIGHT LOGIC ---
	if flashlight_active:
		# Drains completely in ~6.5 seconds!
		flashlight_battery -= delta * 15.0 
		
		# The Low Battery Flicker Effect
		if flashlight_battery < 20.0 and flashlight:
			flashlight.light_energy = randf_range(0.1, 0.8) 
		elif flashlight:
			flashlight.light_energy = 0.8 
			
		# Auto-shutoff when dead
		if flashlight_battery <= 0.0:
			flashlight_battery = 0.0
			flashlight_active = false
			if flashlight: flashlight.visible = false
			shotgun_audio.get_node('click').play() 
			
	# Passive recharge has been DELETED.
	gui.update_flashlight_battery(flashlight_battery, flashlight_active)
	
	gui.update_exhaustion(speed_boost_timer, is_exhausted, delta)
	
	var enemy_dist = 999.0
	var is_valid_enemy = is_instance_valid(active_enemy) and not active_enemy.is_ragdolled
	if is_valid_enemy: enemy_dist = global_position.distance_to(active_enemy.global_position)
	gui.update_proximity_distortion(enemy_dist, is_valid_enemy, delta)

func update_crosshair(delta: float) -> void:
	if not gui.crosshair: return
	
	var is_interactable = false
	var is_enemy = false
	var space_state = get_world_3d().direct_space_state
	var origin = camera_3d.global_position
	
	if object_grabber_shapecast.is_colliding():
		for i in object_grabber_shapecast.get_collision_count():
			var collided = object_grabber_shapecast.get_collider(i)
			if collided is RigidBody3D:
				var obj_query = PhysicsRayQueryParameters3D.create(origin, collided.global_position)
				obj_query.exclude = [player_rid, collided.get_rid()]
				obj_query.collision_mask = 1 
				if not space_state.intersect_ray(obj_query):
					is_interactable = true
					break # Stop processing raycasts once we found a valid interactable object
				
	var end_point = origin + (-camera_3d.global_transform.basis.z * 50.0) 
	var query = PhysicsRayQueryParameters3D.create(origin, end_point)
	query.exclude = self_exclude_array
	var result = space_state.intersect_ray(query)
	if result and (result.collider is Enemy or result.collider.is_in_group("flesh")): is_enemy = true
			
	var target_color = Color.WHITE
	var target_size = Vector2(1.0, 1.0)

	if is_enemy:
		target_color = Color.RED
		target_size = Vector2(1.5, 1.5)
	elif is_interactable:
		target_color = Color.GREEN
		target_size = Vector2(2.0, 2.0)
	
	gui.crosshair.color = lerp(gui.crosshair.color, target_color, delta * 20.0)
	gui.crosshair.size = lerp(gui.crosshair.size, target_size, delta * 20.0)

func handle_interaction() -> void:
	if Input.is_action_just_pressed("interact2"):
		if grabbed_object:
			throw_sound.pitch_scale = randf_range(1.0, 1.2)
			throw_sound.play()
			var throw_dir = -eyes.global_basis.z + Vector3(0.0, 0.2, 0.0)
			if "sleeping" in grabbed_object: grabbed_object.sleeping = false
			var final_impulse = throw_dir.normalized() * throw_force * grabbed_object.mass
			var drop_obj = grabbed_object
			remove_collision_exception_with(drop_obj)
			grabbed_object = null
			rotating_object = false
			drop_obj.apply_central_impulse(final_impulse)
			drop_obj.angular_velocity *= 0.1
		else:
			# Hands are empty? Try to shove!
			perform_shove()

# --- THE SHOVE MECHANIC ---
func perform_shove() -> void:
	if is_switching_weapons or is_reloading or dead or paused: return
	
	if active_slot_index == -1 or inventory[active_slot_index] != "shotgun": return
	if shotgun_animator.is_playing() and shotgun_animator.current_animation == "shove": return 
	
	var shove_cost = 20.0 
	
	# THE FIX: Silent failure to prevent ghost-click gasping!
	if gui.stamina_bar.value < shove_cost and not in_heaven:
		return
		
	if not in_heaven:
		gui.stamina_bar.value -= shove_cost
		stamina_delay_timer = STAMINA_DELAY_MAX 
		if gui.stamina_bar.value <= 0 and not is_exhausted:
			trigger_exhaustion()
	
	if shotgun_animator.has_animation("shove"):
		shotgun_animator.play("shove", 0.1)
		shotgun_audio.get_node('shove').play()

	# --- ADDING THE MEAT ---
	# 1. The Camera Thrust
	var shove_tween = get_tree().create_tween()
	var orig_fov = camera_3d.fov
	var orig_rot = camera_3d.rotation_degrees.x
	
	shove_tween.tween_property(camera_3d, "fov", orig_fov + 8.0, 0.05).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	shove_tween.parallel().tween_property(camera_3d, "rotation_degrees:x", orig_rot - 4.0, 0.05).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	shove_tween.chain().tween_property(camera_3d, "fov", orig_fov, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	shove_tween.parallel().tween_property(camera_3d, "rotation_degrees:x", orig_rot, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# 2. Screen Crunch & Recoil
	trigger_screen_shake(0.15)
	velocity += camera_3d.global_transform.basis.z.normalized() * 3.0 # Pushes the player backward slightly

	var shove_range_sq = 3.5 * 3.5 # Optimized squared check
	var forward_dir = -camera_3d.global_transform.basis.z.normalized()
	
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(enemy):
			if global_position.distance_squared_to(enemy.global_position) <= shove_range_sq:
				var dir_to_enemy = global_position.direction_to(enemy.global_position).normalized()
				
				if dir_to_enemy.dot(forward_dir) > 0.5:
					# --- THE RAGDOLL REACTION ---
					if enemy.is_ragdolled:
						# Kick the corpse!
						if enemy.ragdoll_spine:
							# Angle the kick upward so they lift off the floor beautifully
							var kick_dir = forward_dir + Vector3(0, 0.4, 0)
							# 600.0 is a massive impulse, tweak this up or down to change the ragdoll weight!
							enemy.ragdoll_spine.apply_central_impulse(kick_dir.normalized() * 600.0)
					else:
						# Shove the living!
						var push_dir = forward_dir
						push_dir.y = 0.0 
						
						if enemy.has_method("apply_shove"):
							enemy.apply_shove(push_dir.normalized())

func handle_movement(delta: float) -> void:
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	var speed_multiplier = 1.0
	if speed_boost_timer > 0: speed_multiplier = bean_speed_boost_amount
	if slide_cooldown_timer > 0.0: slide_cooldown_timer -= delta
	var speed_length = Vector2(velocity.x, velocity.z).length()
	
	if in_heaven:
		gui.stamina_bar.value = 100
	else:
		if is_exhausted:
			exhaustion_timer -= delta
			gui.stamina_bar.value = 1.0 
			var blink = (sin(Time.get_ticks_msec() * 0.02) + 1.0) / 2.0
			gui.stamina_bar.modulate = Color(1, 0, 0).lerp(Color(1, 0.6, 0.6), blink)
			if exhaustion_timer <= 0:
				is_exhausted = false
				gui.stamina_bar.modulate = Color.WHITE
				gui.stamina_bar.value = 5.0 
				if out_of_breath_sound.playing: out_of_breath_sound.stop()
		
		if sprinting and input_dir != Vector2.ZERO and !is_exhausted:
			gui.stamina_bar.value -= stamina_drain_sprint
			stamina_delay_timer = STAMINA_DELAY_MAX 
		else:
			if stamina_delay_timer > 0: stamina_delay_timer -= delta 
			elif !is_exhausted: 
				if input_dir == Vector2.ZERO: gui.stamina_bar.value += stamina_regen_idle
				elif crouching or walking: gui.stamina_bar.value += stamina_regen_move

		if gui.stamina_bar.value <= 0 and !is_exhausted: trigger_exhaustion()

	# --- WATER OVERRIDE FOR CROUCHING & SLIDING ---
	if (Input.is_action_pressed('crouch') or is_sliding or (crouching and ceiling_detection.is_colliding())) and not is_underwater:
		if is_on_floor(): current_speed = lerp(current_speed, crouching_speed * speed_multiplier, delta * lerp_speed)
		head.position.y = lerp(head.position.y, crouching_depth, delta * lerp_speed)
		if not standing_collision_shape.disabled:
			standing_collision_shape.disabled = true
			crouching_collision_shape.disabled = false
		
		var minimum_slide_speed = (walking_speed + 0.5) * speed_multiplier
		
		if ((speed_length > minimum_slide_speed and is_on_floor()) or is_sliding) and !is_exhausted:
			if is_on_floor() and slide_boost_available and slide_cooldown_timer <= 0.0:
				slide_sound.play()
				if not in_heaven: gui.stamina_bar.value -= 10
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
		
	elif !ceiling_detection.is_colliding() or is_underwater:
		if standing_collision_shape.disabled:
			standing_collision_shape.disabled = false
			crouching_collision_shape.disabled = true
		head.position.y = lerp(head.position.y, 0.0, (delta * lerp_speed) * 0.8)
		is_sliding = false
		mouse_sens = default_mouse_sens
		if not Input.is_action_pressed("crouch"): slide_boost_available = true 
			
		if Input.is_action_pressed('sprint') and !is_exhausted and (gui.stamina_bar.value != 0 or in_heaven):
			var target_sprint = sprinting_speed * speed_multiplier
			if is_underwater: target_sprint *= 0.85 # Slightly faster swim speed to make diving feel good
			current_speed = move_toward(current_speed, target_sprint, delta * sprint_acceleration)
			walking = false; sprinting = true; crouching = false
		else:
			var target_walk = walking_speed * speed_multiplier
			if is_underwater: target_walk *= 0.65 
			current_speed = lerp(current_speed, target_walk, delta * lerp_speed)
			walking = true; sprinting = false; crouching = false

	# --- DYNAMIC FOV MATH ---
	var target_fov = default_base_fov
	var current_lerp_speed = 6.0
	
	if is_zooming:
		target_fov = zoom_fov
		current_lerp_speed = 12.0
	elif is_sliding: 
		target_fov = 85.0
	else:
		# Pushes the FOV wider as you gain speed, giving a great sense of momentum
		var flat_speed = Vector2(velocity.x, velocity.z).length()
		target_fov += (flat_speed * 0.8) 

	target_fov += panic_fov_modifier
	camera_3d.fov = lerp(camera_3d.fov, target_fov, delta * current_lerp_speed)

	# --- WATER PHYSICS & GRAVITY ---
	if jump_cooldown > 0: jump_cooldown -= delta
	if Input.is_action_just_pressed("jump"): bhop_jump_buffer = BHOP_BUFFER_MAX
	if bhop_jump_buffer > 0: bhop_jump_buffer -= delta

	var cam_swim_dir = Vector3.ZERO 

	if is_underwater:
		# Use cached dynamic height here instead of recalculating 
		var player_eye_height = global_position.y + 1.2
		var depth = water_surface_height - player_eye_height 
		if depth > 0.0: # Submerged
			if sprinting and input_dir != Vector2.ZERO:
				cam_swim_dir = (camera_3d.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
				velocity.y = lerp(velocity.y, cam_swim_dir.y * current_speed, delta * 6.0)
			else:
				velocity.y = move_toward(velocity.y, 1.5, delta * 3.0) 
				if Input.is_action_pressed("jump"): 
					velocity.y = move_toward(velocity.y, 6.0, delta * 15.0)
				elif Input.is_action_pressed("crouch"): 
					velocity.y = move_toward(velocity.y, -4.5, delta * 10.0)
				
		else: # At the surface!
			bobbing_timer += delta * 2.5
			velocity.y = sin(bobbing_timer) * 0.8
			
			if not Input.is_action_pressed("jump") and not Input.is_action_pressed("crouch") and not sprinting:
				var target_y = water_surface_height - 1.2 # Lock to the moving wave!
				global_position.y = lerp(global_position.y, target_y, delta * 4.0)
			
			# Allow jumping OUT of the water
			if bhop_jump_buffer > 0:
				velocity.y = jump_velocity * 0.85
				bhop_jump_buffer = 0.0
				jump_cooldown = 0.25
				jump_sound.play()
	else:
		if not is_on_floor(): velocity += get_gravity() * delta
		
		# Normal Jump Logic
		if bhop_jump_buffer > 0 and is_on_floor() and !ceiling_detection.is_colliding() and jump_cooldown <= 0.0:
			if is_exhausted and not in_heaven:
				if !out_of_breath_sound.playing: out_of_breath_sound.play()
			else:
				if not in_heaven:
					gui.stamina_bar.value -= 5
					velocity.y = jump_velocity
				if in_heaven:
					velocity.y = jump_velocity + 2
				is_sliding = false; free_looking = false
				bhop_jump_buffer = 0.0; jump_cooldown = 0.25
				jump_sound.play()
				animation_player.play('jumping')

	if is_on_floor() and last_velocity.y < -3.0 and not is_underwater:
		animation_player.play('landing')
		if not in_heaven:
			footsteps.play()
		else:
			grass_footsteps.play()
		spawn_landing_footprints()

	var target_dir = Vector3.ZERO
	
	# --- THE FIX: FLATTEN CAMERA VECTOR FOR HORIZONTAL MATH ---
	if is_underwater and sprinting and input_dir != Vector2.ZERO:
		target_dir = Vector3(cam_swim_dir.x, 0, cam_swim_dir.z).normalized()
	else:
		target_dir = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if is_on_floor() and not is_underwater:
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
					var desired_direction = Vector2(target_dir.x, target_dir.z) * current_slide_speed
					flat_vel = flat_vel.lerp(desired_direction, delta * 4.0)
				flat_vel = flat_vel.move_toward(Vector2.ZERO, friction_amount)
				velocity.x = flat_vel.x; velocity.z = flat_vel.y
				
			if Vector2(velocity.x, velocity.z).length() < 1.0: is_sliding = false
		else:
			if in_heaven and bhop_jump_buffer > 0: direction = target_dir if target_dir != Vector3.ZERO else direction
			else: direction = lerp(direction, target_dir, delta * lerp_speed)
	else: # Airborne or Underwater
		var air_accel = SOURCE_AIR_ACCEL
		if is_underwater: air_accel = lerp_speed * 0.6 # Water friction on turning
		elif not in_heaven: air_accel = air_lerp_speed
		
		if target_dir != Vector3.ZERO: direction = lerp(direction, target_dir, delta * air_accel)
		
	if not is_sliding:
		var flat_vel = Vector2(velocity.x, velocity.z)
		if direction:
			var target_vel = Vector2(direction.x, direction.z) * current_speed
			if flat_vel.length() > current_speed:
				if not is_on_floor() or is_underwater:
					var high_speed_target = Vector2(direction.x, direction.z).normalized() * flat_vel.length()
					flat_vel = flat_vel.lerp(high_speed_target, delta * 6.0)
					if !in_heaven or is_underwater:
						var decel = 5.0 * delta
						if is_underwater: decel = 12.0 * delta # Heavy water drag
						var new_length = move_toward(flat_vel.length(), current_speed, decel)
						flat_vel = flat_vel.normalized() * new_length
				else:
					var deceleration = 15.0 * delta
					if crouching: deceleration = 40.0 * delta 
					flat_vel = flat_vel.move_toward(target_vel, deceleration)
					
				velocity.x = flat_vel.x; velocity.z = flat_vel.y
			else:
				velocity.x = target_vel.x; velocity.z = target_vel.y
		else:
			if in_heaven and not is_on_floor() and not is_underwater: pass
			else:
				var flat_vel_length = flat_vel.length()
				
				if is_on_floor() and not is_underwater:
					# Smooth interpolation for ground friction
					var friction = 12.0
					if crouching: friction = 20.0
					
					velocity.x = lerp(velocity.x, 0.0, friction * delta)
					velocity.z = lerp(velocity.z, 0.0, friction * delta)
					
					# Hard stop when extremely slow to prevent infinite sliding drift
					if flat_vel_length < 0.1:
						velocity.x = 0.0
						velocity.z = 0.0
				else:
					# Keep the linear deceleration for mid-air and water
					var decel = 2.0 * delta
					if is_underwater: decel = 25.0 * delta
					velocity.x = move_toward(velocity.x, 0, decel)
					velocity.z = move_toward(velocity.z, 0, decel)
				
	if is_sliding and is_on_floor() and not is_underwater:
		if not slide_loop_sound.playing: slide_loop_sound.play()
		var current_slide_speed = Vector2(velocity.x, velocity.z).length()
		var target_pitch = clamp(current_slide_speed / 10.0, 0.7, 1.3)
		slide_loop_sound.pitch_scale = lerp(slide_loop_sound.pitch_scale, target_pitch, delta * 10.0)
		var target_volume = -40.0 + (clamp(current_slide_speed / 15.0, 0.0, 1.0) * 40.0)
		slide_loop_sound.volume_db = lerp(slide_loop_sound.volume_db, target_volume, delta * 15.0)
	else:
		if slide_loop_sound.playing:
			slide_loop_sound.volume_db = lerp(slide_loop_sound.volume_db, -60.0, delta * 25.0)
			if slide_loop_sound.volume_db <= -50.0: slide_loop_sound.stop()
					
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
	var raw_lean_input = Input.get_axis("leanright", "leanleft")
	var actual_lean_input = raw_lean_input

	# 1. Determine if we are freelooking FIRST
	if Input.is_action_pressed('freelook') or sliding: 
		free_looking = true
		
		# --- THE OVER-THE-SHOULDER OVERRIDE ---
		if raw_lean_input != 0.0:
			# Cancel the physical body lean
			actual_lean_input = 0.0 
			
			# Snap the neck rotation! (1 for Left = +135 deg, -1 for Right = -135 deg)
			var target_neck_rot = raw_lean_input * deg_to_rad(135.0)
			
			# We multiply the lerp speed by 1.5 here so it snaps over the shoulder aggressively
			neck.rotation.y = lerp(neck.rotation.y, target_neck_rot, delta * neck_lerp_speed * 1.5)
	else:
		free_looking = false
		neck.rotation.y = lerp(neck.rotation.y, 0.0, delta * neck_lerp_speed)

	# 2. Process the Lean (Uses actual_lean_input, which forces to 0 if we looked over our shoulder)
	var target_lean = -actual_lean_input * lean_distance
	if actual_lean_input != 0:
		var space_state = get_world_3d().direct_space_state
		var ray_start = head.global_position
		var ray_end = ray_start + (head.global_transform.basis.x * target_lean)
		var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
		var excludes = [player_rid]
		if is_instance_valid(grabbed_object) and grabbed_object is CollisionObject3D: excludes.append(grabbed_object.get_rid())
		query.exclude = excludes
		var result = space_state.intersect_ray(query)
		if result:
			var safe_dist = max(0.0, ray_start.distance_to(result.position) - 0.2)
			target_lean = sign(target_lean) * safe_dist

	current_lean_offset = lerp(current_lean_offset, target_lean, delta * lean_speed)
	current_lean_tilt = lerp(current_lean_tilt, actual_lean_input * deg_to_rad(lean_angle), delta * lean_speed)
	
	var target_freelook_tilt = -deg_to_rad(neck.rotation.y * free_look_angle_amt)
	
	# --- NEW: STRAFE TILT ---
	var target_strafe_tilt = 0.0
	if not sliding and not free_looking and is_on_floor():
		var input_dir := Input.get_vector("left", "right", "forward", "backward")
		# Tilts the camera slightly in the direction you are moving
		target_strafe_tilt = -input_dir.x * deg_to_rad(1.5) 

	# Combine all three procedural rotations
	eyes.rotation.z = current_lean_tilt + target_freelook_tilt + target_strafe_tilt

	# 3. Slide timer check
	if sliding:
		slide_timer -= delta
		if slide_timer <= 0:
			mouse_sens = default_mouse_sens
			sliding = false; free_looking = false
		
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	
	# --- WATER FIX: Stop physical footsteps from triggering while swimming! ---
	if input_dir != Vector2.ZERO and (is_on_floor() or is_underwater) and !sliding:
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
		
		# Only play the heavy boot sounds if we aren't swimming!
		if previous_eye_position < 0 and eyes.position.y > 0 and not is_underwater:
			if in_heaven and grass_footsteps:
				grass_footsteps.play()
			else:
				footsteps.play()
			spawn_footprint()
		previous_eye_position = eyes.position.y
	else:
		head_bobbing_index = 0.0 
		eyes.position.y = lerp(eyes.position.y, 0.0, delta * lerp_speed)
		eyes.position.x = lerp(eyes.position.x, current_lean_offset, delta * lerp_speed)

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
		var grab_dist_sq = 1.5 * 1.5
		for bean in gazunka_beans.get_children():
			if is_instance_valid(bean) and not bean.is_queued_for_deletion():
				if global_position.distance_squared_to(bean.global_position) < grab_dist_sq: 
					try_grabbing(bean)

func hit():
	if !dead:
		current_health -= 1
		regen_timer = time_before_regen 
		if current_health > 0:
			play_random_noise(hit_noises)
			trigger_screen_shake(0.4, "damage")
			if heartbeat_sound and not heartbeat_sound.playing:
				heartbeat_sound.play()
		else:
			dead = true
			is_zooming = false
			play_random_noise(death_noises)
			# --- THE FIX: INSTANTLY HIDE THE WEAPON ---
			# We force the slot to -1 and hide the model so it doesn't get stuck if you die mid-reload!
			active_slot_index = -1
			if shotgun_model:
				shotgun_model.visible = false
			if shotgun_animator:
				shotgun_animator.stop()
				
			if heartbeat_sound and heartbeat_sound.playing:
				heartbeat_sound.stop()
			if compass_arrow:
				compass_arrow.visible = false
			final_time = gui.time.text 
			gui.stamina_bar.visible = false
			gui.time.visible = false
			gui.beans_found_label.visible = false
			if gui.damage_vignette: gui.damage_vignette.visible = false
				
			gui.fade_rect.visible = true
			gui.fade_rect.modulate = Color(0.8, 0, 0, 0.6) 
			
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
			tween.tween_property(gui.fade_rect, "modulate", Color(0, 0, 0, 1.0), 0.6).set_trans(Tween.TRANS_SINE)
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
	if out_of_breath_sound.playing: out_of_breath_sound.stop()
	if night_vision_active:
		turn_off_nightvision()
	wipe_inventory_on_death()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	gui.show_death_screen()

func bean_found():
	bean_count += 1
	if gui.stamina_bar: gui.stamina_bar.value += bean_stamina_boost
	var main = get_tree().current_scene
	if main.has_method("start_the_hunt"):
		main.start_the_hunt()
				
	gui.beans_found_label.text = str(bean_count) + '/7'
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

func play_random_noise(group):
	var noises = group.get_children()
	if noises.size() > 0:
		var random_noise = noises.pick_random()
		random_noise.play()

func has_loot_to_lose() -> bool:
	if bean_count > 0: return true
	for slot in get_all_ui_slots():
		if slot.item_name != "empty": return true
	return false

func execute_quit() -> void:
	if not dead and (in_heaven or win): save_inventory()
	else: wipe_inventory_on_death()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

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
	if is_blackout_run:
		total_time = max(0.0, total_time - 30.0)
		
	GlobalStats.final_time = total_time
	GlobalStats.final_time_string = gui.time.text
	var base_payout = bean_count + bonus_beans
	var final_payout = base_payout
	if total_time < 120.0:
		final_payout *= 2
		print("Speedrun bonus achieved! Payout doubled from ", base_payout, " to ", final_payout)
	if is_blackout_run:
		final_payout *= 3
	GlobalStats.last_run_profit = final_payout
	GlobalStats.add_to_jar(final_payout)
	if total_time < float(GlobalStats.best_time_float):
		GlobalStats.save_score(total_time, gui.time.text)
		GlobalStats.needs_upload = true

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
	
		# --- ADD THIS: FORCE FLASHLIGHT OFF WHEN SWAPPED ---
		elif current_item == "flashlight":
			if flashlight_active:
				flashlight_active = false
				if flashlight: flashlight.visible = false
				shotgun_audio.get_node('click').play()
				gui.update_flashlight_battery(flashlight_battery, flashlight_active)
	
	active_slot_index = target_slot
	gui.update_hotbar(active_slot_index)
	
	if active_slot_index != -1:
		var new_item = inventory[active_slot_index]
		if new_item == "shotgun":
			shotgun_ammo = gui.hotbar_slots[active_slot_index].quantity
			is_chambered = (shotgun_ammo > 0)
			
			# --- THE GHOST FRAME FIX ---
			shotgun_animator.stop()
			
			if shotgun_animator.has_animation("pull_out"):
				shotgun_animator.play("pull_out", 0.0)
				
				# 'advance(0)' forces Godot to instantly calculate the bone positions 
				# for the exact millisecond the animation starts, skipping the 1-frame delay!
				shotgun_animator.advance(0) 
				
				shotgun_audio.get_node('pull_out').play()
				
			# Make it visible ONLY AFTER the bones have been fully calculated
			shotgun_model.visible = true
				
	is_switching_weapons = false

func save_inventory() -> void:
	var hotbar_data = []
	for slot in gui.hotbar_slots:
		if slot.has_method("set_item"): hotbar_data.append({"item": slot.item_name, "qty": slot.quantity})

	var grid_data = []
	if gui.inventory_grid:
		for slot in gui.inventory_grid.get_children():
			if slot.has_method("set_item"): grid_data.append({"item": slot.item_name, "qty": slot.quantity})

	var save_data = {}
	if FileAccess.file_exists(SAVE_FILE_PATH):
		var save_file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
		var json = JSON.new()
		if json.parse(save_file.get_as_text()) == OK: save_data = json.get_data()

	save_data["hotbar"] = hotbar_data
	save_data["grid"] = grid_data
	save_data["shotgun_ammo"] = shotgun_ammo
	
	# --- ADD THIS ---
	save_data["nvg_slot"] = {"item": "empty", "qty": 0}
	if gui.nvg_slot:
		save_data["nvg_slot"] = {"item": gui.nvg_slot.item_name, "qty": gui.nvg_slot.quantity}

	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		print("Inventory saved successfully to ", SAVE_FILE_PATH)

func load_inventory() -> void:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		if gui.inventory_grid and gui.inventory_grid.get_child_count() > 0:
			if gui.inventory_grid.get_child(0).has_method("set_item"):
				gui.inventory_grid.get_child(0).set_item("shotgun_ammo", 12)
		return

	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		var json = JSON.new()
		if json.parse(json_string) == OK:
			var saved_data = json.get_data()
			if saved_data.has("shotgun_ammo"):
				shotgun_ammo = clampi(int(saved_data["shotgun_ammo"]), 0, 4)
				is_chambered = (shotgun_ammo > 0)
			if saved_data.has("hotbar"):
				for i in range(min(saved_data["hotbar"].size(), gui.hotbar_slots.size())):
					var slot_data = saved_data["hotbar"][i]
					if gui.hotbar_slots[i].has_method("set_item"): gui.hotbar_slots[i].set_item(slot_data["item"], slot_data["qty"])
					inventory[i] = slot_data["item"]
			if saved_data.has("grid") and gui.inventory_grid:
				var grid_slots = gui.inventory_grid.get_children()
				for i in range(min(saved_data["grid"].size(), grid_slots.size())):
					var slot_data = saved_data["grid"][i]
					if grid_slots[i].has_method("set_item"): grid_slots[i].set_item(slot_data["item"], slot_data["qty"])
			if saved_data.has("nvg_slot") and gui.nvg_slot:
				gui.nvg_slot.set_item(saved_data["nvg_slot"]["item"], saved_data["nvg_slot"]["qty"])

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if dead or (not in_heaven and not win): wipe_inventory_on_death()
		else: save_inventory()

func wipe_inventory_on_death() -> void:
	var save_data = {}
	if FileAccess.file_exists(SAVE_FILE_PATH):
		var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK: save_data = json.get_data()
			
	save_data["grid"] = []
	save_data["hotbar"] = [{"item": "empty", "qty": 0}, {"item": "empty", "qty": 0}, {"item": "empty", "qty": 0}, {"item": "empty", "qty": 0}]
	save_data["shotgun_ammo"] = 0
	save_data["nvg_slot"] = {"item": "empty", "qty": 0}
	
	var save_file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if save_file: save_file.store_string(JSON.stringify(save_data))

func reward_kill() -> void:
	total_time = max(0.0, total_time - 10.0)
	bonus_beans += 5
	var text_pos = eyes.global_position - (eyes.global_transform.basis.z * 1.5)
	spawn_floating_text(text_pos, "-10 SECONDS!\n+5 BONUS BEANS!", Color(0.0, 1.0, 0.5))

func spawn_floating_text(pos: Vector3, msg: String = "+1 Gazunka Bean!", color: Color = Color(0.955, 1.0, 0.043, 1.0)):
	var popup = Label3D.new()
	popup.text = msg
	popup.pixel_size = 0.005; popup.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	popup.modulate = color; 
	popup.scale = Vector3.ZERO
	get_tree().current_scene.add_child(popup); 
	popup.global_position = pos
	
	var tween = get_tree().create_tween()
	tween.tween_property(popup, "scale", Vector3(1.5, 1.5, 1.5), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(popup, "scale", Vector3.ONE, 0.2)
	tween.parallel().tween_property(popup, "global_position:y", pos.y + 1.5, 1.2).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(popup, "modulate:a", 0.0, 1.2).set_delay(0.5)
	tween.tween_callback(popup.queue_free)

func trigger_bean_sense() -> void:
	# 1. Find all the beans currently in the level
	var active_beans = []
	for bean in get_tree().get_nodes_in_group("beans"):
		if is_instance_valid(bean) and bean.is_inside_tree() and not bean.is_queued_for_deletion():
			if "visible" in bean and bean.visible == false: continue 
			active_beans.append(bean)
			
	if active_beans.size() == 0: return # No beans left!

	# 2. Find the absolute closest one using SQUARED distance (Much Faster!)
	var closest_bean = null
	var closest_dist_sq = INF
	
	for bean in active_beans:
		var dist_sq = global_position.distance_squared_to(bean.global_position)
		if dist_sq < closest_dist_sq:
			closest_dist_sq = dist_sq
			closest_bean = bean
			
	if closest_bean:
		# 3. Ask Godot's Navigation Server for the path
		var map = get_world_3d().navigation_map
		var start_pos = global_position
		var end_pos = closest_bean.global_position
		
		# This returns an array of Vector3 points charting the path around walls!
		var nav_path = NavigationServer3D.map_get_path(map, start_pos, end_pos, true)
		
		if nav_path.size() > 0 and bean_wisp_scene:
			# Put the wisp on cooldown for 5 seconds
			bean_sense_cooldown = wisp_max_cooldown
			
			# Spawn the wisp
			var wisp = bean_wisp_scene.instantiate()
			get_tree().current_scene.add_child(wisp)
			
			# Start it at the player's chest height
			wisp.global_position = global_position + Vector3(0, 1.0, 0) 
			
			# Slightly elevate the path points so the wisp doesn't scrape the floor
			var elevated_path: PackedVector3Array = []
			for point in nav_path:
				elevated_path.append(point + Vector3(0, 1.0, 0))
				
			# Give the wisp the path and let it fly!
			wisp.path = elevated_path

# Returns true if we successfully picked it up, false if the inventory is full
func collect_item(item_name: String, amount: int) -> bool:
	var save_data = {"hotbar": [], "grid": [], "stash_grid": []}
	
	# 1. Open the existing inventory file
	if FileAccess.file_exists(INVENTORY_SAVE_PATH):
		var file = FileAccess.open(INVENTORY_SAVE_PATH, FileAccess.READ)
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			save_data = json.get_data()
			
	# Ensure the player backpack grid array exists and is padded out
	if not save_data.has("grid"): 
		save_data["grid"] = []
	var max_backpack_slots = 16 # Adjust this if Grinky's backpack size is different!
	while save_data["grid"].size() < max_backpack_slots:
		save_data["grid"].append({"item": "empty", "qty": 0})
		
	var amount_left = amount
	var placed = false
	
	# 2. Try to stack the ammo onto an existing pile (Max 16 per slot)
	if item_name == "shotgun_ammo":
		for slot in save_data["grid"]:
			if slot["item"] == item_name and slot["qty"] < 16:
				var space_left = 16 - slot["qty"]
				var add_amount = min(space_left, amount_left)
				
				slot["qty"] += add_amount
				amount_left -= add_amount
				
				if amount_left <= 0:
					placed = true
					break
				
	# 3. If it didn't fit in an existing pile, find an empty slot
	if not placed and amount_left > 0:
		for slot in save_data["grid"]:
			if slot["item"] == "empty":
				slot["item"] = item_name
				slot["qty"] = amount_left
				placed = true
				break
				
	# 4. If we successfully placed it in the JSON data, save the file!
	if placed:
		
		# --- THE GHOST AMMO FIX: SYNC LIVE DATA BEFORE SAVING ---
		# Prevent the hard drive from overwriting the live shotgun ammo!
		var live_hotbar = []
		for slot in gui.hotbar_slots:
			live_hotbar.append({"item": slot.item_name, "qty": slot.quantity})
		save_data["hotbar"] = live_hotbar
		save_data["shotgun_ammo"] = shotgun_ammo
		# --------------------------------------------------------

		var save_file = FileAccess.open(INVENTORY_SAVE_PATH, FileAccess.WRITE)
		if save_file:
			save_file.store_string(JSON.stringify(save_data))
			
			# --- THE FIX: CLOSE THE FILE SO THE HUD CAN READ IT ---
			save_file.close() 
			
		get_tree().call_group("hud", "refresh_inventory_ui")
			
		if has_method("spawn_floating_text"):
			# 1. Raise it up 1.5 meters (roughly camera height)
			var eye_level = Vector3(0, 1.5, 0)
			
			# 2. Push it 1.2 meters straight forward in whatever direction the player is looking
			var forward_push = -global_transform.basis.z * 1.2 
			
			# 3. Add a tiny bit of scatter so multiple pickups don't perfectly overlap
			var random_scatter = Vector3(randf_range(-0.2, 0.2), 0.0, randf_range(-0.2, 0.2))
			
			# Combine them all for the perfect spawn location!
			var perfect_spawn_pos = global_position + eye_level + forward_push + random_scatter
			
			spawn_floating_text(perfect_spawn_pos, "+ " + str(amount) + " Ammo", Color.ORANGE)
			
		return true
	else:
		# The backpack is entirely full!
		# if inventory_full_sound: inventory_full_sound.play()
		return false

# --- MINIGAME CONTROLS ---
func start_crank_minigame():
	if flashlight_battery >= 100.0: return # Don't crank if full!
	is_cranking = true
	
	# Release the mouse so the player can spin the UI crank!
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Tell the GUI to show the crank screen
	if gui.has_method("toggle_crank_ui"):
		gui.toggle_crank_ui(true)

func stop_crank_minigame():
	is_cranking = false
	
	# Lock the mouse back to the center for FPS controls
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if gui.has_method("toggle_crank_ui"):
		gui.toggle_crank_ui(false)
	
	ignore_camera_pan = true
	get_tree().create_timer(0.15).timeout.connect(func(): ignore_camera_pan = false)

func add_flashlight_battery(amount: float) -> void:
	flashlight_battery += amount
	
	if not flashlight_active and flashlight_battery > 2.0:
		flashlight_active = true
		if flashlight: flashlight.visible = true
		shotgun_audio.get_node('click').play()
	
	# Did we hit 100%?
	if flashlight_battery >= 100.0:
		flashlight_battery = 100.0
		
		# Auto-close the minigame!
		stop_crank_minigame()
		
		# Play a satisfying click/ding so the player knows they are full
		shotgun_audio.get_node('click').play() 
		
	# Update the UI bar
	gui.update_flashlight_battery(flashlight_battery, flashlight_active)

# --- HOTBAR & INVENTORY SYNCING ---
func sync_inventory_arrays() -> void:
	# 1. Remember what we were holding BEFORE the inventory changed
	var old_held_item = ""
	if active_slot_index != -1:
		old_held_item = inventory[active_slot_index]

	# 2. Update the player's internal memory to perfectly match the visual hotbar UI
	for i in range(gui.hotbar_slots.size()):
		inventory[i] = gui.hotbar_slots[i].item_name

	# 3. Safety Check 1: The Player's Hands
	if active_slot_index != -1:
		var currently_held = inventory[active_slot_index]

		# THE FIX: If the item in our active hand changed AT ALL, completely deselect the slot!
		if currently_held != old_held_item:
			
			# Cut power to whatever we used to be holding
			if old_held_item == "shotgun" and shotgun_model and shotgun_model.visible:
				shotgun_model.visible = false
				if shotgun_animator.is_playing(): shotgun_animator.stop()

			if old_held_item == "flashlight" and flashlight_active:
				flashlight_active = false
				if flashlight: flashlight.visible = false
				shotgun_audio.get_node('click').play()
				gui.update_flashlight_battery(flashlight_battery, flashlight_active)
				
			# Formally clear the player's hands and remove the UI highlight!
			active_slot_index = -1
			if gui.has_method("update_hotbar"):
				gui.update_hotbar(-1)
			
	# 4. Safety Check 2: The Player's Face (NVGs)
	if gui.nvg_slot and gui.nvg_slot.item_name != "nightvision" and night_vision_active:
		turn_off_nightvision()


func turn_off_nightvision():
	night_vision_active = false
	if nv_light: nv_light.visible = false
	var nv_overlay = gui.get_node_or_null("night_vision_overlay")
	if nv_overlay: nv_overlay.visible = false
	if nv_off_sound: nv_off_sound.play()

# --- SHIFT-CLICK FAST TRANSFER (IN-GAME) ---
func shift_transfer_item(source_slot: Control) -> void:
	if source_slot.item_name == "empty" or not gui: return

	var item_to_move = source_slot.item_name
	var amount_to_move = source_slot.quantity
	var placed = false

	# --- 1. THE NVG FAST-EQUIP INTERCEPT ---
	if item_to_move == "nightvision":
		if source_slot != gui.nvg_slot:
			if gui.nvg_slot and gui.nvg_slot.item_name == "empty":
				# Snap it directly to the face!
				gui.nvg_slot.set_item(item_to_move, amount_to_move)
				source_slot.set_item("empty", 0)
				GlobalStats.play_click()
				sync_inventory_arrays() # Instantly syncs the physical player!
				return

	# --- 2. Determine where to send the item ---
	var target_slots = []
	var source_parent = source_slot.get_parent()

	if source_parent == gui.inventory_grid:
		# Moving from Backpack -> Send to Hotbar
		target_slots = gui.hotbar_slots
	elif source_slot in gui.hotbar_slots or source_slot == gui.nvg_slot:
		# Moving from Hotbar or Face -> Send to Backpack
		if gui.inventory_grid:
			target_slots = gui.inventory_grid.get_children()

	if target_slots.size() == 0: return

	# --- 3. Try to stack it onto an existing pile (AMMO ONLY) ---
	if item_to_move == "shotgun_ammo":
		for target_slot in target_slots:
			if target_slot.has_method("set_item") and target_slot.item_name == item_to_move and target_slot.quantity < 16:
				var space_left = 16 - target_slot.quantity
				var add_amount = min(space_left, amount_to_move)

				target_slot.set_item(item_to_move, target_slot.quantity + add_amount)
				amount_to_move -= add_amount

				if amount_to_move <= 0:
					placed = true
					break

	# --- 4. If there's still amount left, find an empty slot ---
	if not placed:
		for target_slot in target_slots:
			if target_slot.has_method("set_item") and target_slot.item_name == "empty":
				target_slot.set_item(item_to_move, amount_to_move)
				amount_to_move = 0 
				placed = true
				break

	# --- 5. Resolve the transaction ---
	if placed:
		GlobalStats.play_click()
		
		# If the item fully transferred, force the original slot to be empty
		if amount_to_move == 0:
			source_slot.set_item("empty", 0)
		else:
			source_slot.set_item(source_slot.item_name, amount_to_move)

		# Tell the player to check their hands and face to see if anything changed!
		sync_inventory_arrays()

# --- DRAG & DROP RELOAD ---
func force_drag_reload(target_slot_index: int) -> void:
	if is_reloading or is_cranking or dead: return
	
	# 1. Instantly close the inventory UI so the player can watch the reload!
	if gui and gui.inventory_menu.visible:
		gui.toggle_inventory(false)
		
	# 2. Check if we need to pull the shotgun out first
	if active_slot_index != target_slot_index:
		equip_slot(target_slot_index)
		
		# Safely wait for the "pull out weapon" animation to finish
		while is_switching_weapons:
			await get_tree().process_frame
			
	# 3. Trigger your normal reload logic!
	# Because we cancelled the UI drag in step 2, your stack of 5 shells is still 
	# safely in the backpack for this reload function to naturally consume.
	if shotgun_ammo < 4:
		reload_shotgun()

# --- THE 7-BEAN CLIMAX ---
func trigger_panic_attack() -> void:
	if is_panicking: return # Don't accidentally trigger it twice!
	is_panicking = true
	
	# 1. Lock the heartbeat sound on high volume
	if heartbeat_sound:
		heartbeat_sound.volume_db = -17.777
		heartbeat_sound.pitch_scale = 1.2
		heartbeat_sound.play()
		
	# 2. Start a permanent, looping breathing effect on our NEW modifier variable!
	var panic_tween = create_tween().set_loops() 
	
	# Push the modifier up to 20, then back down to 0
	panic_tween.tween_property(self, "panic_fov_modifier", 20.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	panic_tween.tween_property(self, "panic_fov_modifier", 0.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Add a slight dizzying tilt side-to-side (This is safe to apply directly to the camera!)
	panic_tween.parallel().tween_property(camera_3d, "rotation_degrees:z", 2.0, 0.6)
	panic_tween.chain().tween_property(camera_3d, "rotation_degrees:z", -2.0, 0.6)

# --- DYNAMIC WAVE SYNC ---
func get_dynamic_water_height(target_pos: Vector3) -> float:
	var time = Time.get_ticks_msec() / 1000.0
	
	# IMPORTANT: These must match your Shader's parameters perfectly!
	var wave_speed = 1.0
	var wave_frequency = 0.1
	var wave_height = 2.5 
	
	# Calculate the exact height of the wave at these X and Z coordinates
	var wave_offset = sin(target_pos.x * wave_frequency + time * wave_speed) * cos(target_pos.z * wave_frequency + time * wave_speed) * wave_height
	
	return ocean_base_height + wave_offset

# --- GUI PROXY CALLBACKS (Preserves Editor Links!) ---
func _on_button_pressed(): gui._on_button_pressed()
func _on_leaderboard_button_pressed(): gui._on_leaderboard_button_pressed()
func _on_cancel_quit_pressed(): gui._on_cancel_quit_pressed()
func _on_confirm_quit_pressed(): gui._on_confirm_quit_pressed()
func _on_main_menu_pressed(): gui._on_main_menu_pressed()
func _on_settings_button_pressed(): gui._on_settings_button_pressed()
func _on_save_settings_pressed(): gui._on_save_settings_pressed()
func _on_master_slider_value_changed(value: float): gui._on_master_slider_value_changed(value)
func _on_chase_music_slider_value_changed(value: float): gui._on_chase_music_slider_value_changed(value)
func _on_effects_slider_value_changed(value: float): gui._on_effects_slider_value_changed(value)
func _on_voicelines_slider_value_changed(value: float): gui._on_voicelines_slider_value_changed(value)
func _on_ambient_noise_slider_value_changed(value: float): gui._on_ambient_noise_slider_value_changed(value)
func _on_video_button_pressed(): gui._on_video_button_pressed()
func _on_check_box_toggled(toggled_on: bool): gui._on_check_box_toggled(toggled_on)
func _on_resume_pressed(): gui._on_resume_pressed()
func _on_hotbar_checkbox_toggled(toggled_on: bool): gui._on_hotbar_checkbox_toggled(toggled_on)

func _on_sens_slider_drag_ended(value_changed: bool) -> void:
	if value_changed:
		GlobalStats.play_click()

func _on_sens_slider_value_changed(value: float) -> void:
	default_mouse_sens = value / 4.0
	GlobalStats.mouse_sens = value
	update_sens_label(value)
