extends CharacterBody3D

class_name Enemy

signal enemy_dead


# --- NEW COMBAT VARIABLES ---
var max_health: int = 200
var current_health: int = max_health

var is_staggered: bool = false
var stagger_timer: float = 0.0
@export var stagger_duration: float = 0.6 # How long they freeze when shot

#impact sound
@onready var ragdoll_impact_sound: AudioStreamPlayer3D = $ragdoll_impact_sound
var last_impact_time: float = 0.0

# --- NEW: Spine tracking variables ---
var ragdoll_spine: PhysicalBone3D = null
var previous_spine_velocity: Vector3 = Vector3.ZERO

@onready var physical_bone_simulator_3d: PhysicalBoneSimulator3D = $rembotgames_feb_npc/NPC_MAN_FAT/Skeleton3D/PhysicalBoneSimulator3D
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
@onready var death_sounds: Node3D = $death_sounds
@onready var enemy_death_noise: AudioStreamPlayer3D = $death_sounds/enemy_death_noise

@export var player_path: NodePath
@export var attack_range = 2.2
@export var shake_range = 6.0 
@export var base_speed: float = 2.5 
@export var field_of_view_degrees: float = 130.0 
@export var sight_radius: float = 25.0
@export var rotation_speed: float = 8.0 
@export var overshoot_distance: float = 8.0 
@export var hearing_radius: float = 12.0 

# --- FOOTPRINT EXPORTS ---
@export var footprint_scene: PackedScene
@export var footprint_spacing: float = 0.2
@onready var footprint_raycast: RayCast3D = $footprint_raycast

var is_left_foot: bool = true
var has_acknowledged_hiding: bool = false

# NEW TUNING VARIABLES
@export var investigation_time: float = 12.0 
@export var search_wander_radius: float = 15.0 
@export var chase_voiceline_min_interval: float = 4.0 
@export var chase_voiceline_max_interval: float = 8.0 

@onready var random_voicelines: Node3D = $random_voicelines
@onready var allsevenbeans_voiceline: AudioStreamPlayer3D = $allsevenbeans_voiceline
@onready var nav_agent = $NavigationAgent3D
@onready var anim_player: AnimationPlayer = $rembotgames_feb_npc/AnimationPlayer
@onready var enemy_footsteps = $enemy_footsteps
@onready var kick_voiceline = $kick
@onready var debug_marker: MeshInstance3D = $DebugMarker
@onready var timer: Timer = $voiceline_timer
@onready var player_seen_voicelines: Node3D = $player_seen_voicelines
@onready var lost_track_voicelines: Node3D = $lost_track_voicelines
@onready var hear_player_voicelines: Node3D = $hear_player_voicelines
@onready var chasing_voicelines: Node3D = $chasing_voicelines
@onready var icon_component: Node3D = $IconComponent
@onready var hiding_voicelines: Node3D = $hiding_voicelines

var player = null
var speed = 0
var player_is_dead = false
var beans_collected = 0
var nav_map_ready: bool = false
var chosen_voiceline = null
var active_voiceline = null 

var last_known_pos: Vector3 = Vector3.ZERO
var has_last_known_pos: bool = false
var is_chasing: bool = false
var has_screamed_this_chase: bool = false 
var was_seeing_player: bool = false

var investigation_timer: float = 0.0 
var chase_voiceline_timer: float = 0.0

var player_last_frame_pos: Vector3 = Vector3.ZERO 
var player_travel_dir: Vector3 = Vector3.ZERO 

var start_grace_period: bool = true 
var override_patrol_pos: Vector3 = Vector3.ZERO
var has_override_patrol: bool = false
var path_timer: float = 0.0
var current_target_pos: Vector3 = Vector3.ZERO

var head_bobbing_walking_speed = 14.0
var head_bobbing_vector_y = 0.0 
var head_bobbing_index = 0.0
var previous_eye_position = 0.0

var sight_burst_timer: float = 0.0

# --- NEW RAGDOLL STATE ---
var is_ragdolled: bool = false

const ANIM_IDLE = "idle" 
const ANIM_RUN = "run"
const ANIM_ATTACK = "attack"
const ANIM_CANT_SEE_PLAYER = "forward_sad"

func _ready():
	icon_component.get_node('icon_sprite').pixel_size = 0.0003
	add_to_group("enemy") 
	speed = base_speed 
	
	# --- NEW AUTO-FIND PLAYER LOGIC ---
	if player_path:
		player = get_node_or_null(player_path)
		
	if player == null:
		player = get_tree().get_first_node_in_group("player")
		if player == null:
			print("WARNING: Enemy cannot find the player! It will not chase.")
			
	# --- FIX: RECONNECT BROKEN SIGNALS & SYNC BEANS ---
	if player != null:
		# Instantly sync beans in case the enemy spawned AFTER the player got one
		beans_collected = player.bean_count
		
		# Reconnect the signals through code so they never break again
		if not player.bean_collected.is_connected(_on_player_bean_collected):
			player.bean_collected.connect(_on_player_bean_collected)
		if not player.player_paused.is_connected(_on_player_player_paused):
			player.player_paused.connect(_on_player_player_paused)
		if not player.player_unpaused.is_connected(_on_player_player_unpaused):
			player.player_unpaused.connect(_on_player_player_unpaused)
	# --------------------------------------------------
			
	current_target_pos = global_position 
	
	if player:
		player_last_frame_pos = player.global_position
	
	play_animation(ANIM_IDLE)
	if debug_marker: debug_marker.visible = false

	NavigationServer3D.map_changed.connect(_on_nav_map_changed)
	
	if footprint_raycast:
		footprint_raycast.add_exception(self)
	
	if get_tree().current_scene and get_tree().current_scene.scene_file_path.ends_with("heaven.tscn"):
		beans_collected = 7
	
	await get_tree().create_timer(0.5).timeout
	nav_map_ready = true
	
	await get_tree().create_timer(1.5).timeout 
	start_grace_period = false
	start_random_voicelines()

func _on_nav_map_changed(_map_rid):
	nav_map_ready = true

func _physics_process(delta):
	# --- VELOCITY IMPACT TRACKING ---
	if is_ragdolled:
		if ragdoll_spine:
			var current_vel = ragdoll_spine.linear_velocity
			
			# Hitting a wall/floor causes a sudden LOSS of speed
			var speed_loss = previous_spine_velocity.length() - current_vel.length()
			var current_time = Time.get_ticks_msec() / 1000.0
			
			# If he lost more than 4.0 speed instantly, he hit something hard!
			# (The 0.15 delay prevents audio clipping/spamming)
			if speed_loss > 4.0 and current_time > last_impact_time + 0.15:
				last_impact_time = current_time
				ragdoll_impact_sound.global_position = ragdoll_spine.global_position
				
				# Louder sound for harder impacts
				ragdoll_impact_sound.volume_db = linear_to_db(clamp(speed_loss / 25.0, 0.2, 1.0))
				ragdoll_impact_sound.pitch_scale = randf_range(0.8, 1.2)
				ragdoll_impact_sound.play()
				
			previous_spine_velocity = current_vel
			
		# Still return so the AI stops moving!
		return

	if not nav_map_ready: return
	
	# --- NEW: THE STAGGER INTERCEPT ---
	if is_staggered:
		stagger_timer -= delta
		if stagger_timer <= 0.0:
			is_staggered = false
			
		# Slam on the brakes so they slide to a halt while flinching
		velocity.x = move_toward(velocity.x, 0, 40.0 * delta)
		velocity.z = move_toward(velocity.z, 0, 40.0 * delta)
		move_and_slide()
		
		# 'return' forces the script to stop reading here. 
		# They won't chase, attack, or turn until the stagger is over!
		return 
		
	if beans_collected == 0 or player_is_dead:
		velocity = Vector3.ZERO
		if player_is_dead and enemy_footsteps.playing: enemy_footsteps.stop()
		if anim_player and anim_player.current_animation != ANIM_ATTACK:
			play_animation(ANIM_IDLE)
		move_and_slide()
		return
	
	# ATTACK CHECK - This must happen before movement to ensure consistency
	if target_in_range():
		hit_player()
		return # Stop execution so we don't try to move while attacking

	var sees_player = false if start_grace_period else can_see_player()
	
	if not start_grace_period and player and "sprinting" in player:
		if player.sprinting:
			investigate_sound(player.global_position, hearing_radius)
	
	path_timer -= delta
	
	var my_pos_flat = Vector3(global_position.x, 0, global_position.z)
	var target_pos_flat = Vector3(current_target_pos.x, 0, current_target_pos.z)
	var has_arrived = my_pos_flat.distance_to(target_pos_flat) < 2.5 
	
	handle_overshoot(sees_player)
	if player != null: player_last_frame_pos = player.global_position
	
	update_ai_state(sees_player, has_arrived, delta)
	
	was_seeing_player = sees_player

	var current_move_speed = speed
	
	if beans_collected >= 7:
		current_move_speed = 8.3
	elif is_chasing:
		current_move_speed = speed * 1.35
		if sight_burst_timer > 0:
			current_move_speed *= 1.2 
			sight_burst_timer -= delta
		current_move_speed = min(current_move_speed, 7.5) 
	
	update_animation_speed_dynamic(current_move_speed)
	
	head_bobbing_walking_speed = 14.0 * (current_move_speed / 3.0)

	apply_movement(current_move_speed, has_arrived, delta)


func take_damage(amount: int, hit_position: Vector3 = Vector3.ZERO) -> void:
	# Calculate the push direction based on player position
	var push_direction = Vector3.UP
	if player != null:
		push_direction = (global_position - player.global_position).normalized()
	else:
		push_direction = global_transform.basis.z.normalized() 
		
	push_direction += Vector3(0, 0.5, 0) # Add upward lift
	
	# --- THE ULTIMATE SPINE FINDER ---
	var target_bone = null
	var skeleton = physical_bone_simulator_3d.get_parent()
	
	# This forces Godot to recursively search every single node inside the skeleton
	var all_bones = skeleton.find_children("*", "PhysicalBone3D")
	for bone in all_bones:
		if "Spine" in bone.name:
			target_bone = bone
			ragdoll_spine = bone # Save for the impact audio tracker
			break
	
	# If already dead, apply the force and skip the rest!
	if is_ragdolled:
		if target_bone:
			target_bone.apply_central_impulse(push_direction * 250.0)
		return
		
	# --- NEW HEALTH LOGIC ---
	current_health -= amount
	print("Enemy took ", amount, " damage! Health: ", current_health)
	
	if current_health > 0:
		# They survived! Trigger the stagger
		is_staggered = true
		stagger_timer = stagger_duration
		
		# (Optional: Play a flinch/pain sound effect right here if you add one later!)
		return
	
	# --- DEATH LOGIC (Only runs if health <= 0) ---
	is_ragdolled = true
	collision_shape_3d.disabled = true
	
	# --- IMMERSION FIX: SHUT UP IMMEDIATELY ---
	stop_random_voicelines()
	if active_voiceline and active_voiceline.playing:
		active_voiceline.stop()
	# ------------------------------------------
	
	if enemy_footsteps.playing: enemy_footsteps.stop()
	if anim_player: anim_player.stop()
	
	physical_bone_simulator_3d.physical_bones_start_simulation()
	play_random_death_sound()
	emit_signal('enemy_dead')
	
	# Apply initial death force using the bone we found!
	if target_bone:
		target_bone.apply_central_impulse(push_direction * 800.0)


func reset_investigation_variables():
	has_last_known_pos = false 
	is_chasing = false
	has_screamed_this_chase = false 
	has_acknowledged_hiding = false
	path_timer = 0.0 
	investigation_timer = 0.0

func investigate_sound(sound_pos: Vector3, loudness: float) -> void:
	if player_is_dead or beans_collected >= 7: return
	if was_seeing_player: return
	
	if global_position.distance_to(sound_pos) <= loudness:
		if not has_last_known_pos and not is_chasing:
			play_voiceline_from_node(hear_player_voicelines)
			stop_random_voicelines()
			
		last_known_pos = sound_pos
		has_last_known_pos = true
		investigation_timer = investigation_time 
		current_target_pos = last_known_pos
		nav_agent.set_target_position(current_target_pos)

func handle_overshoot(sees_player: bool) -> void:
	if was_seeing_player and not sees_player and is_chasing and beans_collected < 7:
		if player == null: return # <-- SAFETY CHECK ADDED
		
		if "is_hidden" in player and player.is_hidden:
			return 

		var movement_vector = player.global_position - player_last_frame_pos
		var current_player_speed = movement_vector.length() / get_physics_process_delta_time()
		
		player_travel_dir = movement_vector.normalized()
		if player_travel_dir.length_squared() < 0.1:
			player_travel_dir = global_position.direction_to(player.global_position)
			
		var dynamic_overshoot = min(current_player_speed * 1.5, overshoot_distance) 
		var raw_overshoot_pos = player.global_position + (player_travel_dir * dynamic_overshoot)
		
		var space_state = get_world_3d().direct_space_state
		var ray_start = player.global_position + Vector3(0, 1.0, 0)
		var ray_end = raw_overshoot_pos + Vector3(0, 1.0, 0)
		var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
		query.exclude = [self, player]
		query.collision_mask = 1 
		
		var result = space_state.intersect_ray(query)
		if result:
			raw_overshoot_pos = result.position - (player_travel_dir * 1.0)
			raw_overshoot_pos.y = player.global_position.y
			
		var map = nav_agent.get_navigation_map()
		if map.is_valid():
			last_known_pos = NavigationServer3D.map_get_closest_point(map, raw_overshoot_pos)
		else:
			last_known_pos = player.global_position
			
		has_last_known_pos = true
		investigation_timer = investigation_time

func update_ai_state(sees_player: bool, has_arrived: bool, delta: float) -> void:
	var player_is_hidden = player and "is_hidden" in player and player.is_hidden
	
	if not player_is_hidden:
		has_acknowledged_hiding = false

	if beans_collected >= 7:
		if player != null: # <-- SAFETY CHECK ADDED
			current_target_pos = player.global_position
			nav_agent.set_target_position(current_target_pos)
		is_chasing = false 
		stop_random_voicelines()
		if not allsevenbeans_voiceline.playing:
			allsevenbeans_voiceline.play()
		
	elif sees_player and player != null: # <-- SAFETY CHECK ADDED
		if not is_chasing:
			sight_burst_timer = 2.0 
			
		if player_is_hidden and not has_acknowledged_hiding:
			play_voiceline_from_node(hiding_voicelines)
			has_acknowledged_hiding = true
			has_screamed_this_chase = true 
			chase_voiceline_timer = randf_range(chase_voiceline_min_interval, chase_voiceline_max_interval)
			
		elif not has_screamed_this_chase:
			play_voiceline_from_node(player_seen_voicelines)
			has_screamed_this_chase = true
			chase_voiceline_timer = randf_range(chase_voiceline_min_interval, chase_voiceline_max_interval)
			
		last_known_pos = player.global_position
		has_last_known_pos = true 
		is_chasing = true
		investigation_timer = investigation_time 
		current_target_pos = player.global_position
		nav_agent.set_target_position(current_target_pos)
		stop_random_voicelines()
		
	elif has_last_known_pos:
		investigation_timer -= delta
		if investigation_timer <= 0.0:
			play_voiceline_from_node(lost_track_voicelines)
			reset_investigation_variables()
			start_random_voicelines()
			return
			
		if has_arrived:
			var forward_bias = player_travel_dir if player_travel_dir.length_squared() > 0.01 else -global_transform.basis.z
			var random_dir = (Vector3(randf_range(-0.6, 0.6), 0, randf_range(-0.6, 0.6)) + (forward_bias * 1.5)).normalized()
			var local_sweep_point = global_position + (random_dir * randf_range(4.0, 8.0))
			var map = nav_agent.get_navigation_map()
			if map.is_valid():
				current_target_pos = NavigationServer3D.map_get_closest_point(map, local_sweep_point)
				nav_agent.set_target_position(current_target_pos)
				player_travel_dir = global_position.direction_to(current_target_pos)
			
	else:
		is_chasing = false
		if has_arrived or path_timer <= 0.0:
			calculate_patrol_route()

	if is_chasing and has_screamed_this_chase and beans_collected < 7:
		chase_voiceline_timer -= delta
		if chase_voiceline_timer <= 0.0:
			if active_voiceline == null or not active_voiceline.playing:
				play_voiceline_from_node(chasing_voicelines)
			chase_voiceline_timer = randf_range(chase_voiceline_min_interval, chase_voiceline_max_interval)

func calculate_patrol_route() -> void:
	if not nav_map_ready: return
	var target_center = global_position
	var patrol_radius = 10.0
	var next_path_timer = randf_range(6.0, 12.0) 
	
	if has_override_patrol:
		target_center = override_patrol_pos
		has_override_patrol = false
	else:
		var active_beans = []
		for bean in get_tree().get_nodes_in_group("beans"):
			if bean.get_child_count() > 0 and bean.get_child(0).is_in_group("beans"): continue
			if is_instance_valid(bean) and not bean.is_queued_for_deletion() and bean.is_inside_tree():
				if "visible" in bean and bean.visible == false: continue 
				active_beans.append(bean)
				
		if active_beans.size() > 0:
			var beans_left = active_beans.size()
			var give_player_opening = (beans_left <= 3) and (randf() <= 0.75) 
			if give_player_opening:
				target_center = global_position 
				patrol_radius = randf_range(30.0, 60.0)
				next_path_timer = randf_range(12.0, 20.0)
			else:
				var target_bean = active_beans.pick_random()
				target_center = target_bean.global_position
				patrol_radius = randf_range(4.0, 8.0)
		else:
			patrol_radius = 20.0 
			
	var random_dir = Vector3(randf_range(-1.0, 1.0), 0, randf_range(-1.0, 1.0)).normalized()
	var random_point = target_center + (random_dir * patrol_radius)
	var map = nav_agent.get_navigation_map()
	if map.is_valid():
		current_target_pos = NavigationServer3D.map_get_closest_point(map, random_point)
		nav_agent.set_target_position(current_target_pos)
		path_timer = next_path_timer

func apply_movement(current_move_speed: float, has_arrived: bool, delta: float) -> void:
	# 1. ALWAYS calculate gravity first, regardless of what state the enemy is in.
	if not is_on_floor():
		velocity.y -= 9.8 * delta # Standard Godot gravity
	else:
		# Small downward force to keep them snapped to slopes/stairs
		velocity.y = -2.0 
		
	if not player_is_dead:
		if not has_arrived or is_chasing or beans_collected >= 7:
			var next_nav_point = nav_agent.get_next_path_position()
			var dir = next_nav_point - global_position
			dir.y = 0 
			
			if dir.length_squared() > 0.001:
				# Apply movement to X and Z, PRESERVING the Y (gravity) we just calculated
				var flat_velocity = dir.normalized() * current_move_speed
				velocity.x = flat_velocity.x
				velocity.z = flat_velocity.z
				
				var look_target = Vector3(next_nav_point.x, global_position.y, next_nav_point.z)
				if global_position.distance_squared_to(look_target) > 0.01:
					var target_transform = global_transform.looking_at(look_target, Vector3.UP)
					global_transform = global_transform.interpolate_with(target_transform, rotation_speed * delta)
				
				# --- DYNAMIC WALKING ANIMATIONS ---
				if is_chasing or beans_collected >= 7:
					play_animation(ANIM_RUN)
				else:
					play_animation(ANIM_CANT_SEE_PLAYER)
					
			else:
				velocity.x = 0.0
				velocity.z = 0.0
				play_animation(ANIM_IDLE)
		else:
			velocity.x = 0.0
			velocity.z = 0.0
			play_animation(ANIM_IDLE)
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		if allsevenbeans_voiceline.playing:
			allsevenbeans_voiceline.stop()

	# Check if we are moving horizontally (ignoring vertical falling speed)
	var horizontal_speed = Vector2(velocity.x, velocity.z).length()
	
	if horizontal_speed > 0.1:
		head_bobbing_index += head_bobbing_walking_speed * delta
		head_bobbing_vector_y = sin(head_bobbing_index)
		
		if previous_eye_position < 0 and head_bobbing_vector_y > 0:
			if enemy_footsteps: enemy_footsteps.play() 
			spawn_footprint() 
			
			if global_position.distance_squared_to(player.global_position) < (shake_range * shake_range):
				player.trigger_screen_shake(0.08) 
		previous_eye_position = head_bobbing_vector_y

	# Finally, move the enemy with gravity applied!
	move_and_slide()

# --- FOOTPRINT LOGIC ---
func spawn_footprint() -> void:
	if footprint_scene and footprint_raycast and footprint_raycast.is_colliding():
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

func stop_random_voicelines():
	if timer and not timer.is_stopped(): timer.stop()
	if chosen_voiceline and chosen_voiceline.playing: chosen_voiceline.stop()

func start_random_voicelines():
	if timer and timer.is_stopped() and not player_is_dead:
		if not is_chasing and not has_last_known_pos: timer.start()

func play_voiceline_from_node(target_node: Node3D):
	if target_node:
		var lines = target_node.get_children()
		if lines.size() > 0:
			stop_random_voicelines()
			if active_voiceline and active_voiceline.playing:
				active_voiceline.stop()
			var random_line = lines.pick_random()
			if random_line:
				active_voiceline = random_line 
				active_voiceline.play()

func play_animation(anim_name: String):
	if anim_player and anim_player.has_animation(anim_name) and anim_player.current_animation != anim_name:
		anim_player.play(anim_name)

func update_animation_speed_dynamic(temp_speed: float):
	var anim_scale = max(0.5, temp_speed / 3.0) 
	
	if anim_player: 
		# --- NEW: Boost the sad animation speed to match the fast footstep math! ---
		if anim_player.current_animation == ANIM_CANT_SEE_PLAYER:
			anim_player.speed_scale = anim_scale * 1.6 
		else:
			anim_player.speed_scale = anim_scale
			
	if enemy_footsteps: enemy_footsteps.pitch_scale = lerp(0.8, 1.4, (anim_scale - 1.0) / 2.0)

func target_in_range() -> bool:
	if player == null: return false
	var player_is_hidden = "is_hidden" in player and player.is_hidden
	
	# DISTANCE CHECK
	var dist_sq = global_position.distance_squared_to(player.global_position)
	
	# VERTICAL CHECK (Ensures enemy doesn't kill you from the floor above)
	var vertical_dist = abs(global_position.y - player.global_position.y)
	if vertical_dist > 2.0: return false

	if player_is_hidden:
		# If seen hiding, allow a much larger attack range (reaching under table)
		if was_seeing_player: 
			return dist_sq < (3.7 * 3.7) # Increased reach for tables
		return false
			
	return dist_sq < (attack_range * attack_range)
	
func hit_player():
	if not player_is_dead:
		player_is_dead = true 
		is_chasing = false
		stop_random_voicelines()
		
		# Look at the player instantly
		var look_pos = player.global_position
		look_pos.y = global_position.y
		look_at(look_pos, Vector3.UP)
		
		if kick_voiceline: kick_voiceline.play()
		if anim_player: anim_player.speed_scale = 1.0 
		play_animation(ANIM_ATTACK)
		
		await get_tree().create_timer(0.4).timeout
		if player and player.has_method("hit"): player.hit()

func _on_timer_timeout() -> void:
	timer.stop()
	
	if player_is_dead or is_chasing or has_last_known_pos:
		return
		
	if random_voicelines:
		var voicelines = random_voicelines.get_children()
		if voicelines.size() > 0:
			chosen_voiceline = voicelines.pick_random()
			
			# Ensure we don't connect the signal multiple times
			if not chosen_voiceline.finished.is_connected(_on_random_voiceline_finished):
				chosen_voiceline.finished.connect(_on_random_voiceline_finished)
				
			chosen_voiceline.play()

func _on_random_voiceline_finished() -> void:
	# Only restart the timer if we are STILL in a calm state
	if not is_chasing and not has_last_known_pos and not player_is_dead:
		timer.start()

func _on_player_player_paused() -> void:
	player_is_dead = true
	stop_random_voicelines()

func _on_player_player_unpaused() -> void:
	player_is_dead = false
	start_random_voicelines()

func _on_player_bean_collected() -> void:
	beans_collected += 1
	speed = (beans_collected * 0.7) + base_speed
	update_animation_speed_dynamic(speed)
	if player and nav_map_ready and not is_chasing and not has_last_known_pos:
		override_patrol_pos = player.global_position
		has_override_patrol = true
		path_timer = 0.0 

func can_see_player() -> bool:
	if not player: return false
	var player_is_hidden = "is_hidden" in player and player.is_hidden
	
	if player_is_hidden and not was_seeing_player:
		return false
	
	if global_position.distance_to(player.global_position) > sight_radius:
		return false
	
	var my_pos_flat = Vector3(global_position.x, 0, global_position.z)
	var player_pos_flat = Vector3(player.global_position.x, 0, player.global_position.z)
	var to_player_flat = my_pos_flat.direction_to(player_pos_flat)
	var forward_flat = -global_transform.basis.z
	forward_flat.y = 0
	forward_flat = forward_flat.normalized()
	
	var angle = forward_flat.angle_to(to_player_flat)
	if rad_to_deg(angle) > field_of_view_degrees / 2.0: 
		return false
		
	if player_is_hidden and was_seeing_player:
		return true
	
	var space_state = get_world_3d().direct_space_state
	var ray_start = global_position + Vector3(0, 1.0, 0)
	var ray_end = player.global_position + Vector3(0, 1.0, 0)
	var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	query.exclude = [self]
	query.collision_mask = 3 
	
	var result = space_state.intersect_ray(query)
	return result and result.collider == player

func play_random_death_sound():
	if death_sounds:
		var valid_sounds = []
		for child in death_sounds.get_children():
			if child is AudioStreamPlayer3D or child is AudioStreamPlayer:
				valid_sounds.append(child)
		
		if valid_sounds.size() > 0:
			var sound_to_play = valid_sounds.pick_random()
			sound_to_play.play()
			print("Playing death sound: ", sound_to_play.name) # Debug print to console
		else:
			print("WARNING: No audio players found inside death_sounds!")
