extends Node3D

@onready var bg_noise: AudioStreamPlayer = $bg_noise
@onready var game_music_1: AudioStreamPlayer = $game_music_1
@onready var eyes: Node3D = $player/neck/head/eyes
@onready var player: CharacterBody3D = $player
@onready var exit_door: Area3D = $exit_door
@onready var world_environment: WorldEnvironment = $env/WorldEnvironment
@onready var wall_torches: Node3D = $wall_torches
@onready var gazunka_beans: Node3D = $Gazunka_Beans
@onready var navigation_region_3d: NavigationRegion3D = $NavigationRegion3D

# --- Spawning Settings ---
@export_group("Bean Spawning")
@export var min_bean_distance: float = 25.0      
@export var min_player_distance: float = 15.0    
@export var map_padding: float = 2.0
@export var max_spawn_attempts: int = 300   

# --- NEW: ENEMY POOLING ---
@export_group("Enemy Pooling")
@export var max_pool_size: int = 31
var enemy_pool: Array[CharacterBody3D] = []

var current_name = GlobalStats.player_name
var pulse_time: float = 0.0

@export var min_music_pitch: float = 1.5 

# hunt state
@onready var enemy_doors: Node3D = $enemy_doors
@onready var open_noise: AudioStreamPlayer3D = $open_noise
var hunt_started: bool = false

func _ready() -> void:
	randomize()
	# Distribute beans FIRST so it locks onto the real boss
	distribute_beans()
	# THEN silently build the pool of 14 clones!
	setup_enemy_pool()
	
	if exit_door and exit_door.has_node("light"):
		exit_door.get_node("light").light_color = Color.RED
	if player.has_signal("bean_collected"):
		player.bean_collected.connect(_on_player_bean_collected)
	if exit_door:
		exit_door.body_entered.connect(_on_exit_door_body_entered)
		
	if world_environment and world_environment.environment:
		world_environment.environment.fog_light_color = Color('ffefc5')
	
	get_tree().create_timer(15.0).timeout.connect(start_the_hunt)

# --- NEW: PRE-SPAWN HORDES ---
func setup_enemy_pool() -> void:
	var enemy_scene = load("res://scenes/enemy.tscn")
	for i in range(max_pool_size):
		var e = enemy_scene.instantiate()
		e.process_mode = Node.PROCESS_MODE_DISABLED # Turn off AI
		e.visible = false # Turn off rendering
		
		# THE FIX: We MUST add it to the scene tree before we can change its global_position!
		add_child(e) 
		e.global_position = Vector3(0, -1000, 0) # Bury them deep
		
		enemy_pool.append(e)

# The Enemy script will call this to instantly grab a sleeping clone!
func request_enemy() -> CharacterBody3D:
	for e in enemy_pool:
		if e.process_mode == Node.PROCESS_MODE_DISABLED:
			return e
	
	# Emergency Fallback (In case they somehow wipe 15+ enemies)
	var enemy_scene = load("res://scenes/enemy.tscn")
	var e = enemy_scene.instantiate()
	add_child(e)
	return e

func distribute_beans() -> void:
	var nav_map = get_world_3d().get_navigation_map()
	
	while NavigationServer3D.map_get_iteration_id(nav_map) == 0:
		await get_tree().physics_frame
	
	var test_point = Vector3(1000, 0, 1000)
	while NavigationServer3D.map_get_closest_point(nav_map, test_point) == Vector3.ZERO:
		await get_tree().physics_frame
		if Engine.get_frames_drawn() > 300: break 

	await get_tree().create_timer(0.1).timeout

	var bounds: AABB = get_nav_mesh_bounds()
	var min_x = bounds.position.x + map_padding
	var max_x = bounds.position.x + bounds.size.x - map_padding
	var min_z = bounds.position.z + map_padding
	var max_z = bounds.position.z + bounds.size.z - map_padding

	var beans = gazunka_beans.get_children()
	if beans.size() < 7: return
		
	var placed_positions: Array[Vector3] = []
	var player_start_pos = player.global_position

	var enemy = get_tree().get_first_node_in_group("enemy") 
	if is_instance_valid(enemy):
		var enemy_pos = enemy.global_position
		beans[0].global_position = enemy_pos + Vector3(0, 1.2, 0)
		placed_positions.append(enemy_pos)
		print("Enemy Bean locked at: ", enemy_pos)
	else:
		print("Enemy not found for bean spawn 0")

	for i in range(1, 7):
		var bean = beans[i]
		var position_found = false
		var attempts = 0
		var active_min_dist = min_bean_distance
		var active_player_dist = min_player_distance # <-- NEW: Track player distance dynamically

		var last_valid_snap = Vector3.ZERO # <-- NEW: Emergency backup spot

		while not position_found and attempts < max_spawn_attempts:
			attempts += 1
			
			# --- THE FIX: Lower our standards as the loop struggles! ---
			if attempts > 150:
				active_min_dist = 10.0
				active_player_dist = 8.0
			if attempts > 250:
				active_min_dist = 3.0
				active_player_dist = 3.0
			
			var random_pos = Vector3(
				randf_range(min_x, max_x),
				player_start_pos.y,
				randf_range(min_z, max_z)
			)

			var snapped_pos = NavigationServer3D.map_get_closest_point(nav_map, random_pos)

			if snapped_pos.length() < 0.1: continue
			
			# Save this spot! Even if it breaks the distance rules, it's a valid piece of floor.
			last_valid_snap = snapped_pos 

			var dist_to_player = Vector2(snapped_pos.x, snapped_pos.z).distance_to(Vector2(player_start_pos.x, player_start_pos.z))
			if dist_to_player < active_player_dist: continue

			var too_close = false
			for p_pos in placed_positions:
				var d = Vector2(snapped_pos.x, snapped_pos.z).distance_to(Vector2(p_pos.x, p_pos.z))
				if d < active_min_dist:
					too_close = true
					break
			
			if not too_close:
				bean.global_position = snapped_pos + Vector3(0, 0.6, 0)
				placed_positions.append(snapped_pos)
				position_found = true

		# --- THE EMERGENCY FALLBACK FIX ---
		# If it failed 300 times, do NOT throw it into the void. Put it on the last valid floor tile!
		if not position_found:
			if last_valid_snap != Vector3.ZERO:
				bean.global_position = last_valid_snap + Vector3(0, 0.6, 0)
				placed_positions.append(last_valid_snap)
			else:
				# Absolute worst-case scenario: scatter them slightly around the player
				bean.global_position = player_start_pos + Vector3(randf_range(-4.0, 4.0), 1.0, randf_range(-4.0, 4.0))

func get_nav_mesh_bounds() -> AABB:
	if navigation_region_3d and navigation_region_3d.navigation_mesh:
		var nav_mesh = navigation_region_3d.navigation_mesh
		var vertices = nav_mesh.vertices
		
		if vertices.size() == 0:
			return AABB(Vector3(-50, 0, -50), Vector3(100, 2, 100))
			
		var new_aabb = AABB(vertices[0], Vector3.ZERO)
		for i in range(1, vertices.size()):
			new_aabb = new_aabb.expand(vertices[i])
			
		return new_aabb
		
	return AABB(Vector3(-50, 0, -50), Vector3(100, 2, 100))

func _process(delta: float) -> void:
	if player.dead:
		if game_music_1.playing: game_music_1.stop()
		return
	handle_exit_pulse(delta)
	handle_dynamic_music(delta)

# --- THE NEW START LOGIC ---
func start_the_hunt() -> void:
	if hunt_started: return
	hunt_started = true
	
	if player:
		player.timer_started = true
	
	if open_noise and not open_noise.playing:
		open_noise.play()
		
	if enemy_doors:
		for door in enemy_doors.get_children():
			door.queue_free()
			
	# Tell all active enemies to wake up!
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy.has_method("start_the_hunt_intro"):
			enemy.start_the_hunt_intro()

func handle_exit_pulse(delta: float) -> void:
	if player.bean_count >= 7 and exit_door.has_node("light"):
		var l = exit_door.get_node("light")
		pulse_time += delta * 1.5 
		l.light_energy = 2.0 + (sin(pulse_time) * 0.8)

func handle_dynamic_music(delta: float) -> void:
	if player.bean_count >= 7:
		if game_music_1.playing: game_music_1.stop()
		return

	var enemies = get_tree().get_nodes_in_group("enemy")
	var any_alive = false
	var max_speed_factor = 0.0

	for e in enemies:
		if e.process_mode != Node.PROCESS_MODE_DISABLED and not e.is_ragdolled and not e.is_queued_for_deletion():
			any_alive = true
			
			# --- THE FIX: CLAMP THE PHYSICS EXPLOSION ---
			# Never let the speed factor exceed 3.5x normal speed for the audio math!
			var speed_factor = clamp(e.velocity.length() / e.base_speed, 0.0, 3.5)
			if speed_factor > max_speed_factor:
				max_speed_factor = speed_factor

	if any_alive and player.bean_count >= 1:
		if not game_music_1.playing:
			game_music_1.play()
		var target_pitch = max(min_music_pitch, min_music_pitch + (max_speed_factor * 0.5))
		game_music_1.pitch_scale = lerp(game_music_1.pitch_scale, target_pitch, delta * 5.0)
		
	elif not any_alive:
		if game_music_1.playing:
			game_music_1.stop()


func _on_player_bean_collected():
	if player.bean_count >= 7:
		show_exit_warning("HURRY, RETURN TO THE ENTRANCE!")
		game_music_1.stop()
		for torches in wall_torches.get_children():
			torches.light.visible = false
		if world_environment and world_environment.environment:
			world_environment.environment.fog_light_color = Color.RED
		if exit_door and exit_door.has_node("light"):
			exit_door.get_node("light").light_color = Color.GREEN

func _on_exit_door_body_entered(body: Node3D) -> void:
	if body == player:
		if player.bean_count >= 7:
			player.save_final_time() 
			get_tree().call_deferred("change_scene_to_file", "res://scenes/heaven.tscn")
		else:
			if !player.exit_warning_voiceline.playing:
				player.start_voiceline.stop()
				player.exit_warning_voiceline.play()
			show_exit_warning("You need all 7 Gazunka Beans to escape!")

func show_exit_warning(message: String):
	var label = player.get_node("neck/head/eyes/CanvasLayer/exit_warning_label")
	if label:
		label.text = message
		label.visible = true
		await get_tree().create_timer(3.0).timeout
		label.visible = false
