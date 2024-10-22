extends Node

const SERVER_PORT = 8080
const SERVER_IP = "127.0.0.1"
const PLAYERS_TO_START_GAME = 2

var multiplayer_scene = preload("res://scenes/multiplayer_player.tscn")
var _players_spawn_node 
var host_mode_enabled = false	
var multiplayer_mode_enabled = false
var respawn_point = Vector2(30, 20)
var map_seed = 0
var dead_player_id = 0
var start_wall  = false

signal host_joined
signal client_joined

func host():
	print("hosting")
	
	_players_spawn_node = get_tree().get_current_scene().get_node("Players")
	multiplayer_mode_enabled = true
	host_mode_enabled = true
	
	var server_peer = ENetMultiplayerPeer.new()
	server_peer.create_server(SERVER_PORT)
	
	multiplayer.multiplayer_peer = server_peer
	
	multiplayer.peer_connected.connect(_connect_player)
	multiplayer.peer_disconnected.connect(_disconnect_player)
	
	_end_singleplayer()

	map_seed = RandomNumberGenerator.new().randi()
	emit_signal("host_joined")
	
	if not OS.has_feature("dedicated_server"):
		_connect_player(1)
	
func join():
	print("joining")
	
	_players_spawn_node = get_tree().get_current_scene().get_node("Players")
	multiplayer_mode_enabled = true
	
	var client_peer = ENetMultiplayerPeer.new()
	client_peer.create_client(SERVER_IP, SERVER_PORT)
	
	
	multiplayer.server_disconnected.connect(_clean_multiplayer_state)

	multiplayer.multiplayer_peer = client_peer
	_end_singleplayer()

func _connect_player(id: int):
	print("Player %s joined the game." % id)
	
	if !multiplayer.is_server():
		return
		
	var player_to_add = multiplayer_scene.instantiate()
	player_to_add.player_id = id
	player_to_add.name = str(id)

	_players_spawn_node.add_child(player_to_add, true)
	rpc("sync_map_seed", map_seed)

	if _players_spawn_node.get_child_count() == PLAYERS_TO_START_GAME: 
		rpc("start_death_wall")
		start_wall = true

func _disconnect_player(id: int):
	print("Player %s left the game." % id)
	
	if not _players_spawn_node.has_node(str(id)):
		return
	_players_spawn_node.get_node(str(id)).queue_free()

	if !OS.has_feature("dedicated_server"):
		_clean_multiplayer_state()

	## TODO: handle players disconnecting on dedicated server
	
func _end_singleplayer():
	print("ending singleplayer")
	var player_to_remove = get_tree().get_current_scene().get_node("Player")
	player_to_remove.queue_free()
	
func _end_game(losing_player_id):
	if multiplayer.is_server():
		dead_player_id = losing_player_id
		rpc("sync_losing_player_id", dead_player_id)
		_show_end_message(dead_player_id)

func _show_end_message(losing_player_id: int):
	var end_screen = get_tree().get_current_scene().get_node("EndGameScreen")
	var label = end_screen.get_node("Message")
	if multiplayer.get_unique_id() == losing_player_id:
		label.text = "You lost!"
	else:
		label.text = "You won!"
	end_screen.show()

	get_tree().paused = true

func _clean_multiplayer_state():
	# Disconnect signals
	if multiplayer.peer_connected.is_connected(_connect_player):
		multiplayer.peer_connected.disconnect(_connect_player)

	if multiplayer.peer_disconnected.is_connected(_disconnect_player):
		multiplayer.peer_disconnected.disconnect(_disconnect_player)

	if multiplayer.server_disconnected.is_connected(_clean_multiplayer_state):
		multiplayer.server_disconnected.disconnect(_clean_multiplayer_state)

	# Close connection
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()

	multiplayer_mode_enabled = false
	host_mode_enabled = false
	map_seed = 0
	dead_player_id = 0
	start_wall = false


@rpc("any_peer")
func sync_map_seed(mySeed: int):
	map_seed = mySeed
	emit_signal("client_joined")

@rpc("any_peer")
func sync_losing_player_id(losing_player_id: int):
	dead_player_id = losing_player_id
	_show_end_message(dead_player_id)

@rpc("any_peer")
func start_death_wall():
	start_wall = true