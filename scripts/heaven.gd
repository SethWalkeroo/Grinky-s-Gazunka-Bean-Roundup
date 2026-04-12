extends Node3D

@onready var player: CharacterBody3D = $player
@onready var welcome_to_heaven: AudioStreamPlayer3D = $player/welcome_to_heaven
@onready var crickets: Node3D = $crickets
@onready var ambiance: AudioStreamPlayer = $ambiance
@onready var campfire: Node3D = $campfire
@onready var fireflies: Node3D = $fireflies
@onready var better_call_saul: AudioStreamPlayer3D = $better_call_saul

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
			
	if GlobalStats.came_from_main_menu:
		sky_3d.current_time = 6
	else:
		sky_3d.current_time = 0
	player.minimap.visible = false
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
