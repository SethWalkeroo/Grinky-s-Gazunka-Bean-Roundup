extends Node3D

@onready var player: CharacterBody3D = $player
@onready var welcome_to_heaven: AudioStreamPlayer3D = $player/welcome_to_heaven
@onready var crickets: Node3D = $crickets
@onready var characters: Node3D = $characters
@onready var ambiance: AudioStreamPlayer = $ambiance
@onready var campfire: Node3D = $campfire
var player_dead = false
@onready var fireflies: Node3D = $fireflies

@export var stagger_delay: float = 0.2 # Adjust this in the inspector to make it faster or slower
@export var enemy_spawn_delay: float = 60.0 # Set to 60 seconds for production, lower for testing
@onready var sky_3d: Sky3D = $Sky3D

func _ready() -> void:
	sky_3d.current_time = 0
	player.minimap.visible = false
	welcome_to_heaven.play()
	
	# Randomize the starting times of all crickets
	setup_crickets()


func setup_crickets() -> void:
	for cricket in crickets.get_children():
		if cricket is AudioStreamPlayer3D:
			# 1. Randomize start time (play from a random point in the file)
			# This ensures they don't all loop at the exact same second
			var stream_length = cricket.stream.get_length()
			cricket.play(randf_range(0.0, stream_length))
			
			# 2. Optional: Randomize pitch slightly (between 0.9 and 1.1)
			# This makes the crickets sound like they are different sizes/types
			cricket.pitch_scale = randf_range(0.9, 1.1)

func _on_convo_zone_body_entered(body: Node3D) -> void:
	if !player_dead:
		if body is Player:
			for sprite in characters.get_children():
				sprite.billboard = 2
				sprite.get_node('hello').play()
				# Wait for 'stagger_delay' seconds before continuing the loop
				await get_tree().create_timer(stagger_delay).timeout


func _on_convo_zone_body_exited(body: Node3D) -> void:
	if !player_dead:
		if body is Player:
			say_goodbye(false)


func say_goodbye(death: bool):
	for sprite in characters.get_children():
		if !death:
			sprite.billboard = 0
			sprite.get_node('bye').play()
			await get_tree().create_timer(stagger_delay).timeout
		else:
			sprite.billboard = 2
			sprite.get_node('bye').play()
			await get_tree().create_timer(stagger_delay).timeout



func make_sky_black():
	var env = $WorldEnvironment.environment
	
	# Switch background mode to a solid color instead of using the Sky resource
	env.background_mode = Environment.BG_COLOR
	
	# Set that color to pitch black
	env.background_color = Color.BLACK
	
	# Turn off ambient light so the black sky doesn't "light" your player
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.BLACK
