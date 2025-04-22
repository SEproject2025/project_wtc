extends Control

var pop_up_template = preload("res://scenes/pop_up.tscn")
var game_scene_template = preload("res://scenes/game_scene.tscn")
var player_character_template = preload("res://scenes/player_character.tscn")
@onready var host_template = $Host_template
@onready var player_template = $Player_template
@onready var player_list_container = $"Player List/Players/ScrollContainer/VBoxContainer"
@onready var scroll_container = $Chat/ScrollContainer
@onready var scroll = scroll_container.get_v_scroll_bar()

var init_connection = true
@onready var chat_message_dropdown = $Chat/Submit/ChatMessageOptionButton # Get the dropdown node
# --- Preset chat messages ---
const PRESET_MESSAGES: Array[String] = [
	"Hello!", "Hi!", "Ready?", "Start the game!", "Wait",
	"Okay", "Yes", "No", "GG", "GLHF",
	"LOL", ":)", ":(", "Oops!", "Nice!",
	"Thanks!", "BRB", "AFK", "Need help!", "Let's go!",
	"Error 404: Skill not found.",
	"ZA WARUDO! TOKI WA TOMARE!",
	"I got a number one victory royale!",
	"Creeper? Aww, man",
	"🫸🏻🔵🔴🫷🏻🫴🏻🟣"
]
# ---

func _ready():
		# --- Populate the chat message dropdown ---
	chat_message_dropdown.clear() # Clear any old items
	for i in range(PRESET_MESSAGES.size()):
		chat_message_dropdown.add_item(PRESET_MESSAGES[i], i) # Add message with index as ID
	if chat_message_dropdown.item_count > 0:
		chat_message_dropdown.select(0) # Select the first item by default
	# ---

	# Connect signals (ensure User.client is valid)
	User.client.join_lobby.connect(rejoin_lobby)
	User.client.host_name_received.connect(_host_name_received)
	User.client.lobby_messsage_received.connect(_lobby_message_received)
	User.client.other_user_joined_lobby.connect(_other_user_joined_lobby)
	User.client.some_one_left_lobby.connect(_some_one_left_lobby)
	User.client.some_one_left_game.connect(_some_one_left_game)
	User.client.server_changed_host.connect(_server_changed_host)
	User.delete_in_lobby_menu.connect(_delete_in_lobby_menu)
	User.client.restart_lobby_received.connect(_restart_lobby_received)
	User.init_connection()
	scroll.connect("changed", handle_scrollbar_change)
	
	
	$"Lobby Name".text = User.current_lobby_name
	init_player_list()
	User.init_connection()

	setup()


func _delete_in_lobby_menu():
	queue_free()

func _server_changed_host():
	init_player_list()
	setup()
	
func setup():
	if User.current_lobby_state == Constants.LobbyState.STARTED:
		$VBoxContainer/HBoxContainer/Start.visible = false
		$VBoxContainer/GameStatus.visible = true
		$VBoxContainer/GameStatus.text = 'Game started...'
		# $VBoxContainer/HBoxContainer/Spectate.visible = true
	elif User.current_lobby_state == Constants.LobbyState.NOT_STARTED:
		# $VBoxContainer/HBoxContainer/Spectate.visible = false
		$VBoxContainer/HBoxContainer/Start.visible = User.is_host
		if User.is_host:
			$VBoxContainer/GameStatus.visible = false
		else:
			$VBoxContainer/GameStatus.visible = true
			$VBoxContainer/GameStatus.text = "Waiting for host..."


func init_player_list():
	for child in player_list_container.get_children():
		child.free()
	
	for peer_name in User.peers.values():
		if peer_name == User.host_name:
			var new_host_template = host_template.duplicate()
			new_host_template.get_node("Name").text = peer_name
			new_host_template.show()
			player_list_container.add_child(new_host_template)
		else:
			var new_player_template = player_template.duplicate()
			new_player_template.get_node("Name").text = peer_name
			new_player_template.show()
			player_list_container.add_child(new_player_template)
	
	
	var new_player_template  = host_template.duplicate() if User.is_host else player_template.duplicate()
	new_player_template.get_node("Name").text = User.user_name
	new_player_template.show()
	player_list_container.add_child(new_player_template)


func _host_name_received(hostname : String):
	User.init_connection()
	init_player_list()

func _some_one_left_lobby(other_player_name : String):
	
	var container = $Chat/ScrollContainer/VBoxContainer
	
	if not User.is_host and User.peers.size() == 0:
		User.is_host = true
		var msg_node = $Message_template.duplicate()
		msg_node.show()
		msg_node.text = "SYSTEM: " + " You are Host now!"
		container.add_child(msg_node)
	
	User.init_connection()
	init_player_list()
	

func _some_one_left_game(_other_player_id):
	_some_one_left_lobby("")

func _other_user_joined_lobby(username : String):
	var container = $Chat/ScrollContainer/VBoxContainer
	var msg_node = $Message_template.duplicate()	
	msg_node.show()
	msg_node.text = "SYSTEM: " + username + " joined!"
	container.add_child(msg_node)
	
	init_player_list()
	User.init_connection()

func _lobby_message_received(message : String, _user_name : String):
	var container = $Chat/ScrollContainer/VBoxContainer
	var msg_node = $Message_template.duplicate()
	msg_node.show()
	msg_node.text = _user_name + ": " + message
	container.add_child(msg_node)

func _on_return_pressed():
	var pop_up = pop_up_template.instantiate()
	pop_up.set_msg("   returning to the lobby menu...")
	pop_up.is_button_visible(false)
	add_child(pop_up)
	User.is_host = false
	User.host_name = ""
	User.peers.clear()
	User.connection_list.clear()
	User.current_lobby_state = Constants.LobbyState.NOT_STARTED
	User.client.send_left_info(User.current_lobby_name)
	await get_tree().create_timer(1).timeout
	User.client.request_lobby_list()
	get_parent().add_child(load("res://scenes/lobby_menu.tscn").instantiate())
	pop_up.queue_free()
	queue_free()
# --- No longer connected to LineEdit ---
#func _on_message_text_submitted(_new_text):
#	_on_submit_msg_pressed()
# ---

# --- Send selected message from dropdown ---
func _on_submit_msg_pressed():
	var selected_id = chat_message_dropdown.get_selected_id()

	if selected_id != -1: # Check if something is selected
		var msg_text = chat_message_dropdown.get_item_text(selected_id)
		if not msg_text.is_empty(): # Should always be true for presets, but good practice
			print("Sending message: ", msg_text) # Debug print
			if User.client:
				User.client.send_chat_msg(msg_text, User.user_name)
			else:
				push_warning("Cannot send message: User.client is null.")
		# No need to clear the dropdown selection
	else:
		# Optional Debug: Indicate nothing was selected if needed, though default selection helps
		print("No message selected in dropdown.")
# ---

func _on_start_pressed():
	if User.peers.size() == 0:
		var pop_up = pop_up_template.instantiate()
		pop_up.set_msg("you need 2 players!")
		add_child(pop_up)
	elif not User.is_host:
		var pop_up = pop_up_template.instantiate()
		pop_up.set_msg("only the host can start the game!")
		add_child(pop_up)
	else:
		User.client.send_game_starting()


# func _on_spectate_pressed() -> void:
# 	if User.peers.size() == 0:
# 		var pop_up = pop_up_template.instantiate()
# 		pop_up.set_msg("no active games to spectate!")
# 		add_child(pop_up)
# 		return
		
# 	User.is_spectator = true
# 	User.client.notify_spectating()

# 	for peer_id in User.peers.keys():
# 		User.connection_list.get(peer_id).create_offer()
		
func rejoin_lobby(lobby_info: String):
	var arr = lobby_info.split("***")
	var lobby_name = arr[0]
	var pop_up = pop_up_template.instantiate()
	pop_up.set_msg("   joining lobby...")
	pop_up.is_button_visible(false)
	add_child(pop_up)
	User.current_lobby_name = lobby_name
	User.current_lobby_state = arr[1].to_int() as Constants.LobbyState
	print("joined lobby %s !" %lobby_name)
	setup()
	pop_up.queue_free()

func _restart_lobby_received(seed: int, state: Constants.LobbyState):
	User.current_lobby_state = state
	User.current_lobby_seed = seed
	setup()
	
func handle_scrollbar_change():
	scroll_container.scroll_vertical = scroll.max_value
