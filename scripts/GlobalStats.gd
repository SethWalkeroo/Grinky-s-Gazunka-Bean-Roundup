extends Node

# --- RECORD DATA ---
var best_time_float: float = 999999.0
var best_time_string: String = "--:--"
var final_time_string: String = ""
var player_name: String = ""
var final_time: float = 0.0
var needs_upload: bool = false
var came_from_main_menu: bool = false

# --- META PROGRESSION (NEW) ---
var total_beans_collected: int = 0

# --- SETTINGS DATA ---
var master_vol: float = 1.0
var menu_music_vol: float = 1.0
var effects_vol: float = 1.0
var voicelines_vol: float = 1.0
var ambient_noise_vol: float = 1.0
var mouse_sens: float = 0.4
var minimap_on = false

# --- KEYBINDS DATA ---
var keybinds_to_save: Array = [
	"forward", "backward", "left", "right", 
	"jump", "sprint", "crouch", "interact", "interact2",
	"throw", "torch", "freelook", "leanleft", "leanright", "screenshot",
	"reload", "inventory"
]

const SAVE_PATH = "user://gazunka_records.cfg"

func play_click():
	var sfx = AudioStreamPlayer.new()
	add_child(sfx)
	sfx.stream = load("res://audio/SNAP.wav")
	sfx.bus = "menu_snap" 
	sfx.play()
	sfx.finished.connect(sfx.queue_free)
	
func play_start_sound():
	var sfx = AudioStreamPlayer.new()
	add_child(sfx)
	sfx.stream = load("res://audio/start_sound.wav")
	sfx.bus = "start" 
	sfx.play()
	sfx.finished.connect(sfx.queue_free)

func _ready():
	SilentWolf.configure({
		"api_key": "j1quByvqJjUFUeZd5ngC73Vgryhiwj67uf3OIgAc",
		"game_id": "grinkysgazunkabeanroundup",
		"log_level": 1 
	})
	load_data()

# --- META LOGIC (NEW) ---
func add_to_jar(amount: int):
	total_beans_collected += amount
	print("Added ", amount, " beans to jar. Total: ", total_beans_collected)
	check_unlocks()
	save_to_disk()

func check_unlocks():
	# This is where you can trigger global rewards or flags
	if total_beans_collected >= 100:
		# Example: GlobalStats.has_super_torch = true
		pass

func save_score(new_time_float: float, new_time_string: String):
	final_time_string = new_time_string
	if new_time_float < best_time_float:
		best_time_float = new_time_float
		best_time_string = new_time_string
		save_to_disk()

func update_player_name(new_name: String):
	player_name = new_name
	save_to_disk()

func save_to_disk():
	var config = ConfigFile.new()
	
	config.set_value("Records", "best_time_float", best_time_float)
	config.set_value("Records", "best_time_string", best_time_string)
	config.set_value("Records", "player_name", player_name)
	
	# Save Bean Jar (NEW)
	config.set_value("Meta", "total_beans_collected", total_beans_collected)
	
	config.set_value("Settings", "minimap_on", minimap_on)
	config.set_value("Settings", "master_vol", master_vol)
	config.set_value("Settings", "menu_music_vol", menu_music_vol)
	config.set_value("Settings", "effects_vol", effects_vol)
	config.set_value("Settings", "voicelines_vol", voicelines_vol)
	config.set_value("Settings", "ambient_noise_vol", ambient_noise_vol)
	config.set_value("Settings", "mouse_sens", mouse_sens)
	
	for action in keybinds_to_save:
		var events = InputMap.action_get_events(action)
		config.set_value("Binds", action, events)
	
	config.save(SAVE_PATH)

func load_data():
	var config = ConfigFile.new()
	var err = config.load(SAVE_PATH)
	if err == OK:
		best_time_float = config.get_value("Records", "best_time_float", 999999.0)
		best_time_string = config.get_value("Records", "best_time_string", "--:--")
		player_name = config.get_value("Records", "player_name", "")
		
		# Load Bean Jar (NEW)
		total_beans_collected = config.get_value("Meta", "total_beans_collected", 0)
		
		minimap_on = config.get_value("Settings", 'minimap_on', false)
		master_vol = config.get_value("Settings", "master_vol", 1.0)
		menu_music_vol = config.get_value("Settings", "menu_music_vol", 1.0)
		effects_vol = config.get_value("Settings", "effects_vol", 1.0)
		voicelines_vol = config.get_value("Settings", "voicelines_vol", 1.0)
		ambient_noise_vol = config.get_value("Settings", "ambient_noise_vol", 1.0)
		mouse_sens = config.get_value("Settings", "mouse_sens", 0.4)
		
		for action in keybinds_to_save:
			if config.has_section_key("Binds", action):
				var loaded_events = config.get_value("Binds", action)
				InputMap.action_erase_events(action)
				for event in loaded_events:
					InputMap.action_add_event(action, event)
		
		# Apply volumes
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(master_vol))
		# Bus names must match your project's Audio Mixer
		var chase_idx = AudioServer.get_bus_index("chase_music")
		if chase_idx != -1: AudioServer.set_bus_volume_db(chase_idx, linear_to_db(menu_music_vol))
		
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("effects"), linear_to_db(effects_vol))
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("game_voicelines"), linear_to_db(voicelines_vol))
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("ambient_noise"), linear_to_db(ambient_noise_vol))
