extends Node3D

@onready var player: CharacterBody3D = $player
@onready var welcome_to_heaven: AudioStreamPlayer3D = $player/welcome_to_heaven
@onready var crickets: Node3D = $crickets
@onready var ambiance: AudioStreamPlayer = $ambiance
@onready var campfire: Node3D = $campfire
@onready var fireflies: Node3D = $fireflies
@onready var better_call_saul: AudioStreamPlayer3D = $better_call_saul
@onready var victory_bell: AudioStreamPlayer3D = $victory_bell

# --- GLOBAL BELL TRACKERS ---
var bell_check_timer: float = 15.0 # Check every 15 seconds so we don't spam SilentWolf's servers
var last_bell_time: float = 0.0

@onready var sky_3d: Sky3D = $Sky3D
@onready var birds: Node3D = $birds

# Add a state tracker so we don't trigger the loops 60 times a second
var is_daytime: bool = false 

func _ready() -> void:
	# --- THE FIX: TURN OFF REVERB FOR OUTDOORS ---
	var effects_bus = AudioServer.get_bus_index("effects")
	for i in range(AudioServer.get_bus_effect_count(effects_bus)):
		if AudioServer.get_bus_effect(effects_bus, i) is AudioEffectReverb:
			AudioServer.set_bus_effect_enabled(effects_bus, i, false)
	
	var voice_bus = AudioServer.get_bus_index("game_voicelines")
	for i in range(AudioServer.get_bus_effect_count(voice_bus)):
		if AudioServer.get_bus_effect(voice_bus, i) is AudioEffectReverb:
			AudioServer.set_bus_effect_enabled(voice_bus, i, false)
			
	# Establish our baseline time as soon as we load the map
	last_bell_time = Time.get_unix_time_from_system()
			
	if GlobalStats.came_from_main_menu:
		sky_3d.current_time = 6
	else:
		sky_3d.current_time = 0
		
		# --- THE FIX: THIS ONLY RUNS IF YOU WON! ---
		if victory_bell:
			victory_bell.play()
		
			# Send a "score" to a new leaderboard. The score is just the current time!
			SilentWolf.Scores.save_score(GlobalStats.player_name, last_bell_time, "heaven_bell")
			
			# Add a tiny buffer so the player doesn't hear their own ping echo a few seconds later
			last_bell_time += 5.0 
	
	# Route the minimap command through the new GUI node!
	player.gui.minimap.visible = false
	
	welcome_to_heaven.play()
	
	# Determine initial state so the fireflies/crickets start correctly
	is_daytime = (sky_3d.current_time >= 6 and sky_3d.current_time < 19)
	if not is_daytime:
		show_fireflies()
		setup_sound_group(crickets)
	else:
		extinguish_campfire()
		stop_sound_group(crickets)
		setup_sound_group(birds)
		hide_fireflies()
			
	GlobalStats.came_from_main_menu = false

func _physics_process(delta: float) -> void:
	var current_time = sky_3d.current_time
	var should_be_day = (current_time >= 6 and current_time < 19)

	bell_check_timer -= delta
	if bell_check_timer <= 0.0:
		bell_check_timer = 15.0
		check_global_bell()

	# Transition to DAY
	if should_be_day and not is_daytime:
		is_daytime = true
		hide_fireflies()
		stop_sound_group(crickets)
		setup_sound_group(birds)
		extinguish_campfire()
			
	# Transition to NIGHT
	elif not should_be_day and is_daytime:
		is_daytime = false
		show_fireflies()
		stop_sound_group(birds)
		setup_sound_group(crickets)
		start_campfire()


func show_fireflies():
	for firefly in fireflies.get_children():
		firefly.visible = true

func hide_fireflies():
	for firefly in fireflies.get_children():
		firefly.visible = false

func stop_sound_group(things) -> void:
	for thing in things.get_children():
		thing.stop()
		

func setup_sound_group(things) -> void:
	for thing in things.get_children():
		if thing is AudioStreamPlayer3D:
			var stream_length = thing.stream.get_length()
			thing.play(randf_range(0.0, stream_length))
			thing.pitch_scale = randf_range(0.9, 1.1)

func extinguish_campfire():
	campfire.get_node('flames').visible = false
	campfire.get_node('extinguish').play()
	campfire.get_node('fire_noise').stop()
	campfire.get_node('fire_light').visible = false
	campfire.get_node('sparks').visible = false
	campfire.get_node('smoke').position.y = -0.33

func start_campfire():
	campfire.get_node('flames').visible = true
	campfire.get_node('fire_noise').play()
	campfire.get_node('fire_light').visible = true
	campfire.get_node('sparks').visible = true
	campfire.get_node('smoke').position.y = 0.081


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is Player:
		better_call_saul.play()


func check_global_bell() -> void:
	# Ask SilentWolf for the #1 highest score on the secret bell leaderboard
	var sw_result = await SilentWolf.Scores.get_scores(1, "heaven_bell").sw_get_scores_complete
	var scores = sw_result.scores
	
	if scores.size() > 0:
		# The "score" is actually the Unix timestamp of the last victory!
		var latest_ping_time = float(scores[0].score)
		var hero_name = scores[0].player_name
		
		# Is this timestamp newer than the last one we heard?
		if latest_ping_time > last_bell_time:
			last_bell_time = latest_ping_time
			
			if victory_bell:
				# --- DOPAMINE UPGRADE: DYNAMIC PITCH ---
				# Slightly randomize the pitch so it sounds a bit haunting and distant!
				victory_bell.pitch_scale = randf_range(0.85, 1.05)
				victory_bell.play()
				print("A distant bell rings... ", hero_name, " just beat the game!")
