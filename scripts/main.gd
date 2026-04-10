extends Node3D

@onready var bg_noise: AudioStreamPlayer = $bg_noise
@onready var game_music_1: AudioStreamPlayer = $game_music_1
@onready var eyes: Node3D = $player/neck/head/eyes
@onready var player: CharacterBody3D = $player
@onready var enemy = get_tree().get_first_node_in_group("enemy") 
@onready var exit_door: Area3D = $exit_door
@onready var torch_label: Label = $player/neck/head/eyes/CanvasLayer/torch_label
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

var current_name = GlobalStats.player_name
var pulse_time: float = 0.0
var torch_throw = preload("res://scenes/torch.tscn")

@export var torch_count: int = 7
@export var min_music_pitch: float = 1.5 

func _ready() -> void:
	randomize()
	distribute_beans()
	
	update_torch_ui()
	if exit_door and exit_door.has_node("light"):
		exit_door.get_node("light").light_color = Color.RED
	if player.has_signal("bean_collected"):
		player.bean_collected.connect(_on_player_bean_collected)
	if exit_door:
		exit_door.body_entered.connect(_on_exit_door_body_entered)
		
	if world_environment and world_environment.environment:
		world_environment.environment.fog_light_color = Color('ffefc5')

func distribute_beans() -> void:
	var nav_map = get_world_3d().get_navigation_map()
	
	# 1. Wait for map synchronization
	while NavigationServer3D.map_get_iteration_id(nav_map) == 0:
		await get_tree().physics_frame
	
	# 2. Wait for NavServer to return real data
	var test_point = Vector3(1000, 0, 1000)
	while NavigationServer3D.map_get_closest_point(nav_map, test_point) == Vector3.ZERO:
		await get_tree().physics_frame
		if Engine.get_frames_drawn() > 300: break 

	# 3. BRIEF DELAY to let enemy/player physics settle
	await get_tree().create_timer(0.1).timeout

	# 4. Get Dynamic Bounds
	var bounds: AABB = get_nav_mesh_bounds()
	var min_x = bounds.position.x + map_padding
	var max_x = bounds.position.x + bounds.size.x - map_padding
	var min_z = bounds.position.z + map_padding
	var max_z = bounds.position.z + bounds.size.z - map_padding

	var beans = gazunka_beans.get_children()
	if beans.size() < 7: return
		
	var placed_positions: Array[Vector3] = []
	var player_start_pos = player.global_position

	# --- STEP A: Place the Enemy Bean first and lock its position ---
	if is_instance_valid(enemy):
		var enemy_pos = enemy.global_position
		# Move the actual node
		beans[0].global_position = enemy_pos + Vector3(0, 1.2, 0)
		# Add ONLY the X/Z to our exclusion list to ensure no others spawn here
		placed_positions.append(enemy_pos)
		print("Enemy Bean locked at: ", enemy_pos)
	else:
		print("Enemy not found for bean spawn 0")

	# --- STEP B: Place the other 6 beans ---
	for i in range(1, 7):
		var bean = beans[i]
		var position_found = false
		var attempts = 0

		while not position_found and attempts < max_spawn_attempts:
			attempts += 1
			
			var random_pos = Vector3(
				randf_range(min_x, max_x),
				player_start_pos.y,
				randf_range(min_z, max_z)
			)

			var snapped_pos = NavigationServer3D.map_get_closest_point(nav_map, random_pos)

			if snapped_pos.length() < 0.1:
				continue

			# Check distance from player
			var dist_to_player = Vector2(snapped_pos.x, snapped_pos.z).distance_to(Vector2(player_start_pos.x, player_start_pos.z))
			if dist_to_player < min_player_distance:
				continue

			# Check distance from ALL previously placed beans (including the enemy bean)
			var too_close = false
			for p_pos in placed_positions:
				var d = Vector2(snapped_pos.x, snapped_pos.z).distance_to(Vector2(p_pos.x, p_pos.z))
				if d < min_bean_distance:
					too_close = true
					break
			
			if not too_close:
				bean.global_position = snapped_pos + Vector3(0, 0.6, 0)
				placed_positions.append(snapped_pos)
				position_found = true

		if not position_found:
			print("Warning: Could not find spot for bean ", i, ". Consider lowering min_bean_distance.")

func get_nav_mesh_bounds() -> AABB:
	if navigation_region_3d and navigation_region_3d.navigation_mesh:
		var nav_mesh = navigation_region_3d.navigation_mesh
		var vertices = nav_mesh.vertices
		
		if vertices.size() == 0:
			return AABB(Vector3(-50, 0, -50), Vector3(100, 2, 100))
			
		# Initialize AABB with the first vertex
		var new_aabb = AABB(vertices[0], Vector3.ZERO)
		
		# Expand the AABB to include all other vertices
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
	if Input.is_action_just_pressed("throw"):
		throw_torch()

func handle_exit_pulse(delta: float) -> void:
	if player.bean_count >= 7 and exit_door.has_node("light"):
		var l = exit_door.get_node("light")
		pulse_time += delta * 1.5 
		l.light_energy = 2.0 + (sin(pulse_time) * 0.8)

func handle_dynamic_music(delta: float) -> void:
	if game_music_1.playing and is_instance_valid(enemy):
		var current_speed = enemy.velocity.length()
		var speed_factor = (current_speed / enemy.base_speed)
		var target_pitch = max(min_music_pitch, min_music_pitch + (speed_factor * 0.5))
		game_music_1.pitch_scale = lerp(game_music_1.pitch_scale, target_pitch, delta * 5.0)

func throw_torch() -> void:
	if torch_count > 0:
		if player.has_node("throw_sound"):
			player.throw_sound.play()
		var instance = torch_throw.instantiate()
		add_child(instance)
		instance.global_position = player.grabbed_anchor.global_position
		var throw_dir = -eyes.global_basis.z
		instance.apply_central_impulse((throw_dir) + Vector3(0, 1.0, 0))
		torch_count -= 1
		update_torch_ui()
	else:
		print("Out of torches!")

func _on_player_bean_collected():
	if player.bean_count == 1 and not game_music_1.playing:
		game_music_1.play()
	if player.bean_count >= 7:
		show_exit_warning("HURRY, RETURN TO THE ENTRANCE!")
		game_music_1.stop()
		for torches in wall_torches.get_children():
			torches.light.visible = false
		if world_environment and world_environment.environment:
			world_environment.environment.fog_light_color = Color.RED
		if exit_door and exit_door.has_node("light"):
			exit_door.get_node("light").light_color = Color.GREEN

func update_torch_ui() -> void:
	if torch_label:
		torch_label.text = "Torches: " + str(torch_count)

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


func _on_enemy_enemy_dead() -> void:
	game_music_1.stop()
