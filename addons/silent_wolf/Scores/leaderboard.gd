extends CanvasLayer 

const ScoreItem = preload("res://addons/silent_wolf/Scores/ScoreItem.tscn")
signal close_requested
var list_index = 0
var ld_name = "main"

func _ready() -> void:
	self.process_mode = Node.PROCESS_MODE_ALWAYS
	self.layer = 100 
	
	var close_btn = get_node_or_null("Board/CloseButtonContainer/CloseButton")
	if close_btn:
		if close_btn.pressed.is_connected(_on_close_button_pressed):
			close_btn.pressed.disconnect(_on_close_button_pressed)
		close_btn.pressed.connect(_on_close_button_pressed)

	clear_leaderboard()
	fetch_and_render()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"): 
		_on_close_button_pressed()

func fetch_and_render():
	add_loading_scores_message()
	var sw_result = await SilentWolf.Scores.get_scores(0, ld_name).sw_get_scores_complete
	
	# ASCENDING SORT (Lowest time is best)
	var scores_array = sw_result.scores
	scores_array.sort_custom(func(a, b): return float(a.score) < float(b.score))
	
	hide_message()
	render_board(scores_array)

func render_board(scores: Array) -> void:
	clear_leaderboard()
	list_index = 0
	
	if scores.is_empty():
		add_no_scores_message()
		return

	for score in scores:
		add_item(score.player_name, str(score.score))

func add_item(player_name: String, score_value: String) -> void:
	var item = ScoreItem.instantiate()
	list_index += 1
	
	var name_label = item.get_node_or_null("PlayerName")
	var score_label = item.get_node_or_null("Score")
	
	# --- NEW: TOP 3 COLOR LOGIC ---
	var rank_color = Color.WHITE # Default
	if list_index == 1:
		rank_color = Color.GOLD
	elif list_index == 2:
		rank_color = Color.SILVER
	elif list_index == 3:
		rank_color = Color(0.8, 0.5, 0.2) # Bronze
	
	item.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	if name_label: 
		name_label.text = str(list_index) + ". " + player_name
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		# Apply the rank color
		name_label.add_theme_color_override("font_color", rank_color)
		
		if name_label is RichTextLabel:
			name_label.scroll_active = false 
			name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		elif name_label is Label:
			name_label.clip_text = false
			name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		
	if score_label: 
		score_label.text = format_time(float(score_value))
		score_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		# Apply the rank color
		score_label.add_theme_color_override("font_color", rank_color)
		
		if score_label is RichTextLabel:
			score_label.scroll_active = false 
			score_label.autowrap_mode = TextServer.AUTOWRAP_OFF
			score_label.set_text_alignment(HORIZONTAL_ALIGNMENT_RIGHT)
		elif score_label is Label:
			score_label.clip_text = false
			score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	
	var container = get_node_or_null("Board/HighScores/ScoreItemContainer")
	if container:
		container.add_child(item)

func format_time(total_time: float) -> String:
	var m = int(total_time / 60.0)
	var s = int(fmod(total_time, 60.0))
	var ms = int(fmod(total_time, 1.0) * 1000.0)
	return "%02d:%02d.%03d" % [m, s, ms]

func clear_leaderboard() -> void:
	var container = get_node_or_null("Board/HighScores/ScoreItemContainer")
	if container:
		for n in container.get_children():
			n.queue_free()

func add_no_scores_message():
	var msg = get_node_or_null("Board/MessageContainer/TextMessage")
	if msg: 
		msg.text = "No scores yet!"
		get_node_or_null("Board/MessageContainer").show()

func add_loading_scores_message():
	var msg = get_node_or_null("Board/MessageContainer/TextMessage")
	if msg: 
		msg.text = "Fetching Global Scores..."
		get_node_or_null("Board/MessageContainer").show()

func hide_message():
	var msg = get_node_or_null("Board/MessageContainer")
	if msg: msg.hide()

func _on_close_button_pressed() -> void:
	get_tree().paused = false
	close_requested.emit()
