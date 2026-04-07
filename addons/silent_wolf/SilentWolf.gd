extends Node

const version = "0.9.9"
var godot_version = Engine.get_version_info().string

const SWUtils = preload("res://addons/silent_wolf/utils/SWUtils.gd")
const SWHashing = preload("res://addons/silent_wolf/utils/SWHashing.gd")
const SWLogger = preload("res://addons/silent_wolf/utils/SWLogger.gd")

@onready var Auth = Node.new()
@onready var Scores = Node.new()
@onready var Players = Node.new()
@onready var Multiplayer = Node.new()

var config = {
	"api_key": "FmKF4gtm0Z2RbUAEU62kZ2OZoYLj4PYOURAPIKEY",
	"game_id": "YOURGAMEID",
	"log_level": 0
}

var scores_config = {
	"open_scene_on_close": "res://scenes/Splash.tscn"
}

var auth_config = {
	"redirect_to_scene": "res://scenes/Splash.tscn",
	"login_scene": "res://addons/silent_wolf/Auth/Login.tscn",
	"email_confirmation_scene": "res://addons/silent_wolf/Auth/ConfirmEmail.tscn",
	"reset_password_scene": "res://addons/silent_wolf/Auth/ResetPassword.tscn",
	"session_duration_seconds": 0,
	"saved_session_expiration_days": 30
}

var auth_script = load("res://addons/silent_wolf/Auth/Auth.gd")
var scores_script = load("res://addons/silent_wolf/Scores/Scores.gd")
var players_script = load("res://addons/silent_wolf/Players/Players.gd")

func _init():
	print("SW Init timestamp: " + str(SWUtils.get_timestamp()))

func _ready():
	print("SW ready start timestamp: " + str(SWUtils.get_timestamp()))
	Auth.set_script(auth_script)
	add_child(Auth)
	Scores.set_script(scores_script)
	add_child(Scores)
	Players.set_script(players_script)
	add_child(Players)
	print("SW ready end timestamp: " + str(SWUtils.get_timestamp()))

func configure(json_config):
	config = json_config

func configure_api_key(api_key):
	config.apiKey = api_key

func configure_game_id(game_id):
	config.game_id = game_id

func configure_game_version(game_version):
	config.game_version = game_version

func configure_log_level(log_level):
	config.log_level = log_level

func configure_scores(json_scores_config):
	scores_config = json_scores_config

func configure_scores_open_scene_on_close(scene):
	scores_config.open_scene_on_close = scene

func configure_auth(json_auth_config):
	auth_config = json_auth_config

func configure_auth_redirect_to_scene(scene):
	auth_config.open_scene_on_close = scene

func configure_auth_session_duration(duration):
	auth_config.session_duration = duration

func free_request(weak_ref, object):
	if (weak_ref.get_ref()):
		object.queue_free()

func prepare_http_request() -> Dictionary:
	var request = HTTPRequest.new()
	var weakref = weakref(request)
	if OS.get_name() != "Web":
		request.set_use_threads(true)
	request.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().get_root().call_deferred("add_child", request)
	var return_dict = {
		"request": request, 
		"weakref": weakref
	}
	return return_dict

func send_get_request(http_node: HTTPRequest, request_url: String):
	var headers = [
		"x-api-key: " + SilentWolf.config.api_key, 
		"x-sw-game-id: " + SilentWolf.config.game_id,
		"x-sw-plugin-version: " + SilentWolf.version,
		"x-sw-godot-version: " + godot_version 
	]
	headers = add_jwt_token_headers(headers)
	
	# --- THE FIX: Wait until the node is actually ready in the tree ---
	while is_instance_valid(http_node) and not http_node.is_inside_tree():
		await get_tree().process_frame
	
	if not is_instance_valid(http_node): return

	SWLogger.debug("Method: GET")
	SWLogger.debug("request_url: " + str(request_url))
	SWLogger.debug("headers: " + str(headers))
	http_node.request(request_url, headers) 

func send_post_request(http_node, request_url, payload):
	var headers = [
		"Content-Type: application/json", 
		"x-api-key: " + SilentWolf.config.api_key, 
		"x-sw-game-id: " + SilentWolf.config.game_id,
		"x-sw-plugin-version: " + SilentWolf.version,
		"x-sw-godot-version: " + godot_version 
	]
	headers = add_jwt_token_headers(headers)
	
	var paths_with_values_to_hash: Dictionary = {
		"save_score": ["player_name", "score"],
		"push_player_data": ["player_name", "player_data"]
	}
	for path in paths_with_values_to_hash:
		var values_to_hash = []
		if check_string_in_url(path, request_url):
			var fields_to_hash = paths_with_values_to_hash[path]
			for field in fields_to_hash:
				var value = payload[field]
				if typeof(payload[field]) == TYPE_DICTIONARY:
					value = JSON.stringify(payload[field])
				values_to_hash = values_to_hash + [value]
			var timestamp = SWUtils.get_timestamp()
			values_to_hash = values_to_hash + [timestamp]
			var hashed = SWHashing.hash_values(values_to_hash)
			headers.append("x-sw-act-tmst: " + str(timestamp))
			headers.append("x-sw-act-dig: " + hashed)
			break
	
	# --- THE FIX: Wait until the node is actually ready in the tree ---
	while is_instance_valid(http_node) and not http_node.is_inside_tree():
		await get_tree().process_frame
	
	if not is_instance_valid(http_node): return

	var query = JSON.stringify(payload)
	SWLogger.debug("Method: POST")
	SWLogger.debug("request_url: " + str(request_url))
	SWLogger.debug("headers: " + str(headers))
	SWLogger.debug("query: " + str(query))
	http_node.request(request_url, headers, HTTPClient.METHOD_POST, query)

func add_jwt_token_headers(headers: Array) -> Array:
	if Auth.sw_id_token != null:
		headers.append("x-sw-id-token: " + Auth.sw_id_token)
	if Auth.sw_access_token != null:
		headers.append("x-sw-access-token: " + Auth.sw_access_token)
	return headers

func check_string_in_url(test_string: String, url: String) -> bool:
	return test_string in url

func build_result(body: Dictionary) -> Dictionary:
	var error = null
	var success = false
	if "error" in body:
		error = body.error
	if "success" in body:
		success = body.success
	return {
		"success": success,
		"error": error
	}

func check_auth_ready():
	if !Auth: await get_tree().process_frame

func check_scores_ready():
	if !Scores: await get_tree().process_frame

func check_players_ready():
	if !Players: await get_tree().process_frame

func check_sw_ready():
	if !Auth or !Scores or !Players: await get_tree().process_frame
