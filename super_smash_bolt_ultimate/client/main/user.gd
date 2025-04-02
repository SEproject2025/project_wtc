extends Node

var client : Client
var user_name : String = ""
var host_name : String = ""
var current_lobby_name : String = ""
var current_lobby_state : Constants.LobbyState = Constants.LobbyState.NOT_STARTED
var current_lobby_seed : int
var current_lobby_list : String = ""
var is_host : bool = false
var ID = -1
var peers : Dictionary
var game_scene_template = preload("res://scenes/game_scene.tscn")
var player_character_template = preload("res://scenes/player_character.tscn")
var spawn_positions : Dictionary = {}
var is_spectator : bool = false

var connection_list : Dictionary = {}
var rtc_peer : WebRTCMultiplayerPeer

signal reset
signal delete_in_lobby_menu

func after_main_menu_init():
	client.offer_received.connect(_offer_received)
	client.answer_received.connect(_answer_received)
	client.ice_received.connect(_ice_received)
	client.reset_connection.connect(reset_connection)
	client.game_start_received.connect(_game_start_received)
	client.spawn_positions_received.connect(_spawn_positions_received)

func init_connection():
	rtc_peer = WebRTCMultiplayerPeer.new()
	rtc_peer.create_mesh(ID)
	
	connection_list.clear()
	
	for peer_id in peers.keys():
		var connection = set_up_connection(peer_id)
		rtc_peer.add_peer(connection, peer_id)
	
	for peer_id in peers.keys():
		print("PEER LIST: Name: %s with ID# %d" %[peers.get(peer_id), peer_id])
	
	rtc_peer.peer_connected.connect(_peer_connected)
	rtc_peer.peer_disconnected.connect(_peer_disconnected)
	get_tree().get_multiplayer().multiplayer_peer = rtc_peer

func session_created(type: String, sdp: String, connection : WebRTCLibPeerConnection):
		connection.set_local_description(type, sdp)
		if type == "offer":
			client.send_offer(type, sdp, connection_list.find_key(connection))
			print("sending offer")
		else:
			client.send_answer(type, sdp, connection_list.find_key(connection))
			print("sending answer")

func ice_created(media: String, index: int, _name: String, connection : WebRTCLibPeerConnection):
		client.send_ice(media, index, _name, connection_list.find_key(connection))
		print("sending ice")

func _ice_received(media: String, index: int, _name: String, sender_id):
	connection_list.get(sender_id).add_ice_candidate(media, index, _name)
	print("ice received")

func _offer_received(type: String, sdp: String, sender_id):
	connection_list.get(sender_id).set_remote_description(type, sdp)
	print("offer received")

func _answer_received(type: String, sdp: String, sender_id):
	connection_list.get(sender_id).set_remote_description(type, sdp)
	print("answer received")

func _peer_connected(id : int):
	delete_in_lobby_menu.emit()
	
	var game_scene_node = get_node_or_null("../game_scene")

	if not game_scene_node:
		var game_scene = game_scene_template.instantiate()
		game_scene.set_multiplayer_authority(User.ID)
		game_scene.name = "game_scene"
		get_parent().add_child(game_scene)
		game_scene_node = get_node("../game_scene")
	
	var check_my_player = game_scene_node.get_node_or_null("%s" %ID)
	if not check_my_player:
		var player_character = player_character_template.instantiate()
		player_character.set_multiplayer_authority(User.ID)
		player_character.name = str(User.ID)
		if is_spectator:
			player_character.spectator = true
		player_character.global_position = spawn_positions[User.ID] if spawn_positions.has(User.ID) else Vector2.ZERO
		game_scene_node.add_child(player_character)
	
	var player_character = player_character_template.instantiate()
	player_character.set_multiplayer_authority(id)
	player_character.name = str(id)
	player_character.global_position = spawn_positions[id] if spawn_positions.has(id) else Vector2.ZERO
	game_scene_node.add_child(player_character)

	User.client.other_user_joined_game.emit(id)

	for connection in connection_list.values():
		print("Peer connected with id %d" %connection_list.find_key(connection))

func _peer_disconnected(id : int):
	print("Peer disconnected with id %d" %id)
	
	if connection_list.has(id):
		var connection = connection_list[id]
		if rtc_peer and rtc_peer.has_peer(id):
			rtc_peer.remove_peer(id)  # Remove from mesh network first
		connection.close()  # Then close the connection
		connection_list.erase(id)  # Finally remove from our list
	
	if peers.has(id):
		peers.erase(id)

	var peer_node = get_node_or_null("../game_scene/%s" %id)    
	if peer_node:
		await get_tree().create_timer(0.1).timeout
		peer_node.queue_free()

func _game_start_received(peer_ids : String):
	var arr = peer_ids.split("***", false)
	
	for id_string in arr:
		User.connection_list.get(id_string.to_int()).create_offer()

func _spawn_positions_received(spawnPositions : Dictionary):
	spawn_positions = spawnPositions

func reset_connection():
	for connection in connection_list.values():
		connection.close()
	
	var game_scene = get_tree().get_root().get_node_or_null("game_scene")
	if game_scene:
		game_scene.queue_free()
	client.queue_free()
	client = Client.new()
	user_name = ""
	is_host = false
	current_lobby_list = ""
	current_lobby_name = ""
	host_name = ""
	print("User reset!")
	ID = -1
	peers.clear()
	is_spectator = false
	reset.emit()

func connect_to_peer(peer_id: int):
	if connection_list.has(peer_id):
		return 
		
	var connection = set_up_connection(peer_id)
	
	if rtc_peer == null:
		rtc_peer = WebRTCMultiplayerPeer.new()
		rtc_peer.create_mesh(ID)
		rtc_peer.peer_connected.connect(_peer_connected)
		rtc_peer.peer_disconnected.connect(_peer_disconnected)
		get_tree().get_multiplayer().multiplayer_peer = rtc_peer
		
	rtc_peer.add_peer(connection, peer_id)

func set_up_connection(peer_id: int) -> WebRTCPeerConnection:
	var connection = WebRTCPeerConnection.new()
	connection.initialize({"iceServers": [
			{ "urls": ["stun:stun.l.google.com:19302"] },  # Keep the public STUN server
			{
				"urls": [
					"turn:turn.silfsy.com:3478"
				],
				"username": "bolt",  # Your TURN username
				"credential": "4w4y1011"  # Your TURN password (replace with actual credential!)
			}
		]})
	connection.session_description_created.connect(session_created.bind(connection))
	connection.ice_candidate_created.connect(ice_created.bind(connection))
	connection_list[peer_id] = connection
	return connection
