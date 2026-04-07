extends CanvasLayer

@onready var number_1_player: RichTextLabel = $number_1_player
@onready var motd_button: Button = $motd_button
@onready var bean_jar: RichTextLabel = $bean_jar
@onready var sarah: AudioStreamPlayer = $sarah
@onready var menu_music: AudioStreamPlayer = $menu_noises/main_music

@onready var gpu_particles_2d: GPUParticles2D = $GPUParticles2D
var heart_png = 'res://heart.png'
var heart_gradient_tex: GradientTexture1D

# --- NEW: PARTICLE SAVE STATE VARIABLES ---
var orig_vel_min: float = 0.0
var orig_vel_max: float = 0.0
var orig_color_ramp: Texture2D = null
var orig_color_init_ramp: Texture2D = null
var orig_color: Color = Color.WHITE
var orig_emission_shape: int = 0
var orig_emission_extents: Vector3 = Vector3.ZERO
var orig_particle_pos: Vector2 = Vector2.ZERO
var orig_hue_var: float = 0.0
var orig_gravity: Vector3 = Vector3.ZERO
var particles_saved: bool = false
var is_easter_egg_active: bool = false

var sarah_quote = '[color=black]"[/color][color=cyan][i]Don[color=black]\'[/color]t you know[color=black]?[/color] She[color=black]\'[/color]s been here all along[color=black],[/color] in a [color=pink]d[/color][color=white]r[/color][color=pink]e[/color][color=white]a[/color][color=pink]m[/color][color=black],[/color] she belongs in a [color=pink]d[/color][color=white]r[/color][color=pink]e[/color][color=white]a[/color][color=pink]m[/color][/i][/color][color=black]."[/color] [color=brown]-Alex G[/color]'

# --- EXACT AUDIO TIMESTAMP TRACKERS ---
var sarah_playback_position: float = 0.0
var menu_music_playback_position: float = 0.0

# --- CONFIG & DATA ---
const MAX_CHAR_LIMIT = 12
const BANNED_WORDS = [
	"nigger", "beaner", "gook", "chink", "nigga", "faggot", "fag", "nickgurs", "fuck", "shit", "bitch", "cunt",
	"coon", "spook", "fuck"
]

@onready var menu_background: TextureRect = $menu_background

var motds = [
	'"[i]Aww man[/i]" [color=green]-creepah[/color]',
	'"[i]This is how I [color=gold]Gelmar[/color] my life up[/i]" [rainbow]-Pinegrove[/rainbow]',
	'"[i]China number 1[/i]" [color=red]-China[/color] [color=yellow](probably)[/color]',
	'"[i]The successful warrior is the average man, with [color=red]laser-like[/color] focus.[/i]" [rainbow]-Bruce Lee[/rainbow]',
	'"[i]The [color=brown]root[/color] of suffering is [color=pink]attachment[/color].[/i]" [color=gold]-Buddha[/color]',
	'"[i]All I was doing was trying to get home from work.[/i]" [rainbow]-Rosa Parks[/rainbow]',
	'"[i]I [color=white]came[/color], I [color=cyan]saw[/color], I [color=gold]conquered[/color].[/i]" [color=red]-Julius Caesar[/color]',
	'"[i]Good artists copy, great artists steal.[/i]" [rainbow]-Pablo Picasso[/rainbow]',
	'"[i]The only thing that [color=red]interferes[/color] with my learning is my education.[/i]" [rainbow]-Albert Einstein[/rainbow]',
	'[color=yellow]"[/color][i][color=orange]Fire will attract more [color=purple]attention[/color] than any other [color=purple]cry[/color] for help[/color][/i][color=yellow]" [/color] [color=white]-Jean-Michel Basquiat[/color]',
	'"[i]I [color=red]need[/color] your [color=tan]feet[/color] more than [color=pink]you[/color] do.[/i]" [color=cyan]-Cameron Winter[/color]',
	'"[i]Fly like a [color=purple]butterfly[/color], sting like a [color=yellow]bee[/color].[/i]" [color=orange]-Muhammad Ali[/color]',
	'"[i][color=gold]Winners[/color] [color=red]never quit[/color], and [color=red]quitters never[/color] [color=green]win[/color].[/i]" [color=green]-Vince Lombardi[/color]',
	'"[i]If not [color=red]us[/color], who? If not [color=red]now[/color], when?[/i]" [color=blue]-John F. Kennedy[/color]',
	'"[i]You’ll never find a [rainbow]rainbow[/rainbow] if you’re looking [color=gray]down[/color].[/i]" [color=cyan]-Charlie Chaplin[/color]',
	'"[i]Well done is better than well said.[/i]" [color=lightgreen]-Benjamin Franklin[/color]',
	'"[i][color=red]No.[/color][/i]" [rainbow]-Rosa Parks[/rainbow]',
	'"[i]Genius is [color=gold]eternal[/color] patience.[/i]" [rainbow]-Michelangelo[/rainbow]',
	'"[i]If you [color=red]judge[/color] people, you have no time to [color=pink]love[/color] them.[/i]" [color=gold]-Mother Teresa[/color]',
	'"[i]Those who [color=red]judge[/color] people, you have no time to [color=pink]love[/color] them.[/i]" [color=gold]-Mother Teresa[/color]',
	'"[i]Those who [color=red]dare[/color] to [color=red]fail miserably[/color] can achieve greatly.[/i]" [color=blue]-John F. Kennedy[/color]',
	'"[i]Be [rainbow]yourself[/rainbow]; everyone else is already taken.[/i]" [color=gold]-Oscar Wilde[/color]',
	'"[i]You miss [color=green]100 percent[/color] of the shots you [color=red]never[/color] take.[/i]" [color=cyan]-Wayne Gretzky[/color]',
	'"[i]The essence of strategy is [color=gold]choosing[/color] what [color=red]not[/color] to do.[/i]" [color=cyan]-Michael Porter[/color]',
	'"[i]A mind is like a parachute, it doesn\'t work if it\'s not open[/i]" [rainbow]-Frank Zappa[/rainbow]',
	'"[i]You don\'t have to be [color=green]great[/color] to [color=gold]start[/color], but you have to [color=green]start[/color] to be [color=gold]great[/color].[/i]" [rainbow]-Zig Ziglar[/rainbow]',
	'"[i]Infinite [color=cyan]futures[/color] become a single [color=red]past[/color]; Everyone whimpers, nobody [color=gray]lasts[/color].[/i]" [color=gold]-Alex G[/color]',
	 '[color=black]"[/color][color=cyan][i]Don[color=black]\'[/color]t you know[color=black]?[/color] She[color=black]\'[/color]s been here all along[color=black],[/color] in a [color=pink]d[/color][color=white]r[/color][color=pink]e[/color][color=white]a[/color][color=pink]m[/color][color=black],[/color] she belongs in a [color=pink]d[/color][color=white]r[/color][color=pink]e[/color][color=white]a[/color][color=pink]m[/color][/i][/color][color=black]."[/color] [color=brown]-Alex G[/color]',
	'"[i][color=cyan]Sometimes you never realize the value of a moment until it becomes a memory[/color][/i]" [color=red]-Dr.[/color] [color=white]Seuss[/color]',
	'"[i]A man who wants to [color=green]lead[/color] the [color=brown]orchestra[/color] must turn his [color=black]back[/color] on the crowd.[/i]" [color=brown]-Max Lucado[/color]',
	'"[i]The only way to do [color=green]great work[/color] is to [color=pink]love[/color] what you do.[/i]” [color=red]–Steve Jobs[/color]',
	'“[i][color=cyan]Life[/color] is what happens when you’re [color=red]busy[/color] making other plans.[/i]” [color=gold]–John Lennon[/color]',
	'“[i]It is [color=red]never[/color] too late to be what you might have been.[/i]” [color=cyan]–George Eliot[/color]',
	'“[i][color=red]Doubt[/color] kills more dreams than [color=red]failure[/color] ever will.[/i]” [color=cyan]–Suzy Kassem[/color]',
	'“[i][color=gold]The greatest glory[/color] in living lies not in never falling, but in [color=gold]rising[/color] every time we fall.[/i]” [color=brown]–Nelson Mandela[/color]',
	'“[i]Your time is [color=red]limited[/color], don’t waste it living someone else’s [color=cyan]life[/color].[/i]” [color=red]–Steve Jobs[/color]',
	'“[i]The future belongs to those who [color=gold]believe[/color] in the [color=purple]beauty[/color] of their dreams.[/i]” –Eleanor Roosevelt',
	'“[i]Change your thoughts and you change your [color=green]world[/color].[/i]” [color=cyan]–Norman Vincent Peale[/color]',
	'“[i]The man who moves a [color=green]mountain[/color] begins by carrying away [color=gray]small stones[/color].[/i]” [color=red]–Confucius[/color]',
	'“[i]It does not matter how [color=orange]slowly[/color] you go as long as you do not [color=red]stop[/color].[/i]” [color=red]–Confucius[/color]',
	'“[i]We do not [color=cyan]remember[/color] days; we remember [color=gold]moments[/color].[/i]” [color=cyan]–Cesare Pavese[/color]',
	'“[i][color=green]Success[/color] usually comes to those who are [color=orange]too busy[/color] to be looking for it.[/i]” [color=red]–Henry David Thoreau[/color]',
	'“[i]What we [color=brown]think[/color], we [color=green]become[/color].[/i]” [color=gold]–Buddha[/color]',
	'“[i]Keep your face always toward the [color=gold]sunshine[/color]—and [color=black]shadows[/color] will fall behind you.[/i]” –Walt Whitman',
	'“[i][color=gold]Motivation[/color] is what gets you started. [color=green]Habit[/color] is what keeps you going.[/i]” [color=orange]–Jim Ryun[/color]',
	'“[i]The secret of getting [color=cyan]ahead[/color] is getting [color=green]started[/color].[/i]” [color=red]–Mark Twain[/color]',
]

# --- NEW: ANTI-REPEAT VARIABLE ---
var last_motd_index: int = -1

@export var rainbow_speed: float = 0.1 
@export var color_lerp_speed: float = 2.0 

# --- BACKGROUND VIBE CONFIG ---
@export var bg_cycle_speed: float = 0.04
@export var bg_rotation_speed: float = 0.08
var bg_hue: float = 0.0

var time_passed: float = 0.0
var target_rank_color: Color = Color.WHITE 
var has_faded_in_number_1: bool = false 

# --- PROFILE NODES ---
@onready var profile_panel: Panel = $ProfilePanel
@onready var name_input: LineEdit = $ProfilePanel/LineEdit
@onready var create_btn: Button = $ProfilePanel/CreateButton
@onready var profile_creation_voiceline: AudioStreamPlayer = $menu_noises/profile_creation_voiceline
@onready var creation_warning_label: RichTextLabel = $ProfilePanel/creation_warning_label

# --- MAIN MENU NODES ---
@onready var menu_container: VBoxContainer = $MenuButtons
@onready var welcome_label: Label = $MenuButtons/Label
@onready var start_btn: Button = $MenuButtons/StartButton
@onready var quit_btn: Button = $MenuButtons/QuitButton
@onready var title: Label = $MenuButtons/title
@onready var motd: RichTextLabel = $motd
@onready var settings_panel: ColorRect = $settings_panel
const leaderboard_scene = preload("uid://byi13mqxxc8vm")
@onready var video_settings: ColorRect = $video_settings
@onready var minimap_checkbox: CheckBox = $video_settings/VBoxContainer/HBoxContainer/minimap_checkbox

# --- CONTROLS REBINDING NODES & STATE ---
@onready var controls_btn: Button = $Button 
@onready var controls_settings: ColorRect = $controls_settings
@onready var controls_grid: GridContainer = $controls_settings/ScrollContainer/GridContainer

var is_rebinding: bool = false
var action_to_rebind: String = ""
var button_to_rebind: Button = null

# --- AUDIO NODES ---
@onready var master_slider: HSlider = $settings_panel/VBoxContainer/HBoxContainer/master_slider
@onready var menu_music_slider: HSlider = $settings_panel/VBoxContainer/HBoxContainer2/menu_music_slider
@onready var effects_slider: HSlider = $settings_panel/VBoxContainer/HBoxContainer3/effects_slider
@onready var voicelines_slider: HSlider = $settings_panel/VBoxContainer/HBoxContainer4/voicelines_slider
@onready var ambient_noise_slider: HSlider = $settings_panel/VBoxContainer/HBoxContainer5/ambient_noise_slider

@onready var effects_test: AudioStreamPlayer = $test_audio/effects_test
@onready var voiceline_test: AudioStreamPlayer = $test_audio/voiceline_test
@onready var test_ambient_noise: AudioStreamPlayer = $menu_noises/test_ambient_noise
@onready var button_hover_noise: AudioStreamPlayer = $menu_noises/button_hover_noise
@onready var button_click_noise: AudioStreamPlayer = $menu_noises/button_click_noise
@onready var name_taken: AudioStreamPlayer = $menu_noises/name_taken
@onready var bad_word_noise: AudioStreamPlayer = $menu_noises/bad_word_noise
@onready var everyone_has_name_noise: AudioStreamPlayer = $menu_noises/everyone_has_name_noise
@onready var sound: AudioStreamPlayer = $menu_noises/sound
@onready var video: AudioStreamPlayer = $menu_noises/video
@onready var controls: AudioStreamPlayer = $menu_noises/controls
@onready var leaderboard_noise: AudioStreamPlayer = $menu_noises/leaderboard_noise

var master_bus = AudioServer.get_bus_index("Master")
var menu_music_bus = AudioServer.get_bus_index("menu_music")
var effects_bus = AudioServer.get_bus_index("effects")
var voicelines_bus = AudioServer.get_bus_index("game_voicelines")
var ambient_noise_bus = AudioServer.get_bus_index('ambient_noise')
var sarah_bus = AudioServer.get_bus_index("sarah") 

func _ready() -> void:
	randomize()
	
	# --- NEW: Enhanced Fade-In/Out Gradient ---
	var grad = Gradient.new()
	grad.offsets = [0.0, 0.2, 0.8, 1.0] # Control where the colors transition
	grad.colors = [
		Color(1, 1, 1, 0),       # Start completely transparent
		Color(1, 1, 1, 1),       # Fade into solid white
		Color("ff6bb5"),         # Transition to solid pink
		Color("ff6bb5", 0)       # Fade out completely transparent
	]
	heart_gradient_tex = GradientTexture1D.new()
	heart_gradient_tex.gradient = grad
	
	_init_background_vibe()
	minimap_checkbox.button_pressed = GlobalStats.minimap_on
	set_motd()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	name_input.max_length = MAX_CHAR_LIMIT
	
	if number_1_player: number_1_player.modulate.a = 0.0 
	if controls_settings: controls_settings.visible = false
	if controls_btn:
		controls_btn.mouse_entered.connect(_play_hover_sound)
		controls_btn.pressed.connect(_on_controls_button_pressed)
	
	if controls_grid:
		for action in GlobalStats.keybinds_to_save:
			var expected_btn_name = action.capitalize().replace(" ", "") + "Btn"
			var btn = controls_grid.get_node_or_null(expected_btn_name)
			if btn:
				btn.mouse_entered.connect(_play_hover_sound)
				btn.pressed.connect(_on_rebind_button_pressed.bind(btn, action))
				_update_button_text(btn, action)
			
		var default_binds_btn = controls_grid.get_node_or_null("default_bindings")
		if default_binds_btn:
			default_binds_btn.mouse_entered.connect(_play_hover_sound)
			default_binds_btn.pressed.connect(_on_default_bindings_pressed)
	
	if GlobalStats.player_name != "" and GlobalStats.player_name != "Guest":
		setup_main_menu()
		await get_tree().create_timer(0.2).timeout
		check_and_apply_rank_colors()
	else:
		setup_profile_creation()

	master_slider.set_value_no_signal(GlobalStats.master_vol)
	menu_music_slider.set_value_no_signal(GlobalStats.menu_music_vol)
	effects_slider.set_value_no_signal(GlobalStats.effects_vol)
	voicelines_slider.set_value_no_signal(GlobalStats.voicelines_vol)
	ambient_noise_slider.set_value_no_signal(GlobalStats.ambient_noise_vol)

func _init_background_vibe() -> void:
	if menu_background:
		var grad = Gradient.new()
		grad.set_color(0, Color.BLACK)
		grad.set_color(1, Color.BLACK)
		var tex = GradientTexture2D.new()
		tex.gradient = grad
		tex.fill = GradientTexture2D.FILL_RADIAL
		tex.fill_from = Vector2(0.5, 0.5)
		menu_background.texture = tex
		menu_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		menu_background.stretch_mode = TextureRect.STRETCH_SCALE

func _process(delta: float) -> void:
	_update_background_vibe(delta)
	if menu_container.visible:
		if title:
			time_passed += delta * rainbow_speed
			var current_hue = wrapf(time_passed, 0.0, 1.0)
			title.add_theme_color_override("font_color", Color.from_hsv(current_hue, 0.8, 1.0))
		if welcome_label:
			var current_color = welcome_label.get_theme_color("font_color")
			if current_color == null: current_color = Color.WHITE
			var new_color = current_color.lerp(target_rank_color, delta * color_lerp_speed)
			welcome_label.add_theme_color_override("font_color", new_color)

func _update_background_vibe(delta: float) -> void:
	if menu_background and menu_background.texture is GradientTexture2D:
		var tex = menu_background.texture
		bg_hue = wrapf(bg_hue + (delta * bg_cycle_speed), 0.0, 1.0)
		var color_1 = Color.from_hsv(bg_hue, 0.6, 0.08)
		var color_2 = Color.from_hsv(wrapf(bg_hue + 0.3, 0.0, 1.0), 0.5, 0.18)
		tex.gradient.set_color(0, color_1)
		tex.gradient.set_color(1, color_2)
		var rot_t = Time.get_ticks_msec() * 0.001 * bg_rotation_speed
		tex.fill_to = Vector2(0.5, 0.5) + Vector2(cos(rot_t), sin(rot_t)) * 0.6

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("screenshot"):
		GlobalStats.play_click()
		await get_tree().process_frame
		var capture = get_viewport().get_texture().get_image()
		var sys_time = Time.get_datetime_string_from_system().replace(":", "_")
		var filename = "user://screenshot_" + sys_time + ".png"
		capture.save_png(filename)

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

	if event.is_action_pressed('pause'):
		if settings_panel.visible or controls_settings.visible or video_settings.visible:
			_on_save_settings_pressed() 

func setup_main_menu():
	profile_panel.visible = false
	menu_container.visible = true
	motd_button.visible = true 
	bean_jar.visible = true
	if controls_btn: controls_btn.visible = true
	if welcome_label: welcome_label.text = "Welcome, " + GlobalStats.player_name + "!"

func setup_profile_creation():
	profile_panel.visible = true
	menu_container.visible = false
	bean_jar.visible = false
	motd_button.visible = false 
	if controls_btn: controls_btn.visible = false
	name_input.grab_focus()

# --- MOTD LOGIC & EASTER EGG ---
func set_motd():
	var random_text = ""
	
	if motds.size() <= 1:
		if motds.size() == 1:
			random_text = motds[0]
	else:
		var new_index = randi() % motds.size()
		while new_index == last_motd_index:
			new_index = randi() % motds.size()
		last_motd_index = new_index
		random_text = motds[new_index]

	if random_text == sarah_quote:
		# AUDIO LOGIC
		if menu_music and menu_music.playing:
			menu_music_playback_position = menu_music.get_playback_position()
			menu_music.stop()
		if sarah and not sarah.playing:
			sarah.play(sarah_playback_position)
			
		# PARTICLE LOGIC
		if gpu_particles_2d and gpu_particles_2d.process_material is ParticleProcessMaterial:
			var mat = gpu_particles_2d.process_material as ParticleProcessMaterial
			
			# Snapshot the original settings before changing them
			if not particles_saved:
				orig_vel_min = mat.initial_velocity_min
				orig_vel_max = mat.initial_velocity_max
				orig_color_ramp = mat.color_ramp
				orig_color_init_ramp = mat.color_initial_ramp
				orig_color = mat.color
				orig_emission_shape = mat.emission_shape
				orig_emission_extents = mat.emission_box_extents
				orig_hue_var = mat.hue_variation_max
				orig_gravity = mat.gravity
				orig_particle_pos = gpu_particles_2d.position
				particles_saved = true
				
			gpu_particles_2d.texture = load(heart_png)
			
			# Overwrite all color settings so ONLY the pink gradient shows
			mat.color = Color.WHITE
			mat.color_initial_ramp = null
			mat.color_ramp = heart_gradient_tex
			mat.hue_variation_max = 0.0
			mat.hue_variation_min = 0.0
			
			# Set a slow floating velocity
			mat.initial_velocity_min = 2.0
			mat.initial_velocity_max = 8.0
			mat.gravity = Vector3(0, -8, 0) # Gentle upward drift
			
			# Spread the particles evenly across the entire screen
			var vp_size = get_viewport().get_visible_rect().size
			gpu_particles_2d.position = Vector2(vp_size.x / 2, vp_size.y / 2) # Center it
			mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
			mat.emission_box_extents = Vector3(vp_size.x / 2, vp_size.y / 2, 1)

			# Clear out the old particles and start fresh
			if not is_easter_egg_active:
				gpu_particles_2d.restart()
				is_easter_egg_active = true

	else:
		# AUDIO LOGIC
		if sarah and sarah.playing:
			sarah_playback_position = sarah.get_playback_position()
			sarah.stop()
		if menu_music and not menu_music.playing:
			menu_music.play(menu_music_playback_position)
			
		# RESTORE PARTICLE LOGIC
		if gpu_particles_2d and gpu_particles_2d.process_material is ParticleProcessMaterial and is_easter_egg_active:
			gpu_particles_2d.texture = null
			
			# If we altered the material previously, revert it!
			if particles_saved:
				var mat = gpu_particles_2d.process_material as ParticleProcessMaterial
				mat.initial_velocity_min = orig_vel_min
				mat.initial_velocity_max = orig_vel_max
				mat.color_ramp = orig_color_ramp
				mat.color_initial_ramp = orig_color_init_ramp
				mat.color = orig_color
				mat.emission_shape = orig_emission_shape
				mat.emission_box_extents = orig_emission_extents
				mat.hue_variation_max = orig_hue_var
				mat.gravity = orig_gravity
				gpu_particles_2d.position = orig_particle_pos

			# Clear out the old hearts and start fresh
			gpu_particles_2d.restart()
			is_easter_egg_active = false

	# Display the MOTD text
	motd.text = '[wave amp=20.0 freq=5.0 connected=1]%s[/wave]' % random_text

func check_and_apply_rank_colors():
	if not is_inside_tree(): return
	target_rank_color = Color.WHITE
	var sw_query = SilentWolf.Scores.get_scores(100, "main")
	var sw_result = await sw_query.sw_get_scores_complete
	if sw_result.has("scores") and sw_result.scores.size() > 0:
		var scores = sw_result.scores
		scores.sort_custom(func(a, b): return float(a.score) < float(b.score))
		if number_1_player and scores.size() > 0:
			var top_player = scores[0].player_name
			number_1_player.text = "[wave amp=20 freq=5 connect=1][center][color=gold]All hail " + top_player + "! 👑[/color][/center][/wave]"
			if not has_faded_in_number_1:
				number_1_player.modulate.a = 0.0 
				var tween = create_tween()
				tween.tween_property(number_1_player, "modulate:a", 1.0, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
				has_faded_in_number_1 = true
			else:
				number_1_player.modulate.a = 1.0 
		if scores.size() > 0 and scores[0].player_name == GlobalStats.player_name:
			target_rank_color = Color.GOLD
		elif scores.size() > 1 and scores[1].player_name == GlobalStats.player_name:
			target_rank_color = Color.SILVER
		elif scores.size() > 2 and scores[2].player_name == GlobalStats.player_name:
			target_rank_color = Color(0.8, 0.5, 0.2) 
		else:
			target_rank_color = Color.WHITE

func _on_start_button_pressed() -> void:
	GlobalStats.play_click()
	GlobalStats.play_start_sound()
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_quit_button_pressed() -> void:
	GlobalStats.play_click()
	get_tree().quit()

func _on_leaderboard_button_pressed() -> void:
	GlobalStats.play_click()
	leaderboard_noise.play()
	if get_tree().root.has_node("Leaderboard"): return
	if leaderboard_scene:
		var lb = leaderboard_scene.instantiate()
		lb.name = "Leaderboard"
		lb.process_mode = Node.PROCESS_MODE_ALWAYS
		lb.close_requested.connect(_handle_leaderboard_close.bind(lb))
		get_tree().root.add_child(lb)
		if lb is CanvasLayer: lb.layer = 100

func _handle_leaderboard_close(node_to_free):
	GlobalStats.play_click()
	node_to_free.queue_free() 
	check_and_apply_rank_colors()

func _on_settings_button_pressed() -> void:
	GlobalStats.play_click()
	sound.play()
	motd_button.visible = false
	bean_jar.visible = false
	menu_container.visible = false
	if controls_btn: controls_btn.visible = false
	settings_panel.visible = true

func _on_video_settings_pressed() -> void:
	GlobalStats.play_click()
	video.play()
	motd_button.visible = false
	bean_jar.visible = false
	menu_container.visible = false
	if controls_btn: controls_btn.visible = false
	video_settings.visible = true

func _on_save_settings_pressed() -> void:
	GlobalStats.play_click()
	controls_settings.visible = false
	settings_panel.visible = false
	video_settings.visible = false
	menu_container.visible = true
	bean_jar.visible = true
	if controls_btn: controls_btn.visible = true
	motd_button.visible = true
	GlobalStats.minimap_on = minimap_checkbox.button_pressed
	GlobalStats.master_vol = master_slider.value
	GlobalStats.menu_music_vol = menu_music_slider.value
	GlobalStats.effects_vol = effects_slider.value
	GlobalStats.voicelines_vol = voicelines_slider.value
	GlobalStats.ambient_noise_vol = ambient_noise_slider.value
	GlobalStats.save_to_disk()

func _on_master_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(master_bus, linear_to_db(value))

func _on_menu_music_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(menu_music_bus, linear_to_db(value))

func _on_effects_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(effects_bus, linear_to_db(value))
	if not effects_test.playing: effects_test.play()

func _on_voicelines_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(voicelines_bus, linear_to_db(value))
	if not voiceline_test.playing: voiceline_test.play()

func _on_ambient_noise_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(ambient_noise_bus, linear_to_db(value))
	if test_ambient_noise and not test_ambient_noise.playing: test_ambient_noise.play()

func _on_create_button_pressed() -> void:
	var chosen_name = name_input.text.strip_edges()
	if chosen_name == "" or chosen_name == null:
		creation_warning_label.text = "[wave amp=30 freq=10][color=yellow]You gotta have a name![/color][/wave]"
		everyone_has_name_noise.play()
		return 
	
	create_btn.disabled = true
	create_btn.text = "Checking..."
	
	var sweep_check = await SilentWolf.Scores.get_scores(1000, "main").sw_get_scores_complete
	if sweep_check.has("scores"):
		for s in sweep_check.scores:
			if s.player_name.to_lower() == chosen_name.to_lower():
				create_btn.disabled = false
				create_btn.text = "Name Taken!"
				name_taken.play()
				return
	
	await SilentWolf.Scores.save_score(chosen_name, 999.99, "main").sw_save_score_complete
	profile_creation_voiceline.play()
	GlobalStats.update_player_name(chosen_name)
	setup_main_menu()
	check_and_apply_rank_colors()

func _play_hover_sound():
	if button_hover_noise and not button_hover_noise.playing:
		button_hover_noise.play()

func _play_click_sound():
	GlobalStats.play_click()

func _on_motd_button_pressed() -> void:
	GlobalStats.play_click()
	set_motd()

func _on_button_pressed() -> void:
	bean_jar.visible = false
	controls.play()
	motd_button.visible = false

func _on_controls_button_pressed() -> void:
	GlobalStats.play_click()
	menu_container.visible = false
	bean_jar.visible = false
	if controls_btn: controls_btn.visible = false
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
