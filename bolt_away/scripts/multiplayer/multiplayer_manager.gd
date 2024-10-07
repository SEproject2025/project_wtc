extends Node

const SERVER_PORT = 8080
const SERVER_IP = "127.0.0.1"

var multiplayer_scene = preload("res://scenes/multiplayer_player.tscn")

var _players_spawn_node
var host_mode_enabled = false	
var multiplayer_mode_enabled = false
var respawn_point = Vector2(30, 20)
var map_seed: int = 10
var seedGenerated: bool = false
signal multiplayer_mode_changed(multiplayer_mode_enabled: bool)
signal player_joined(multiplayer_mode_enabled: bool)

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
	print("server seed" + str(map_seed))
	sync_map_seed(map_seed)
	emit_signal("multiplayer_mode_changed", multiplayer_mode_enabled)
	
	if not OS.has_feature("dedicated_server"):
		_connect_player(1)
	
func join():
	print("joining")
	
	multiplayer_mode_enabled = true
	
	var client_peer = ENetMultiplayerPeer.new()
	client_peer.create_client(SERVER_IP, SERVER_PORT)
	
	multiplayer.multiplayer_peer = client_peer
	_end_singleplayer()

func _connect_player(id: int):
	print("Player %s joined the game." % id)
	
	var player_to_add = multiplayer_scene.instantiate()
	player_to_add.player_id = id
	player_to_add.name = str(id)
	
	_players_spawn_node.add_child(player_to_add, true)
	rpc_id(id, "sync_map_seed", map_seed)


func _disconnect_player(id: int):
	print("Player %s left the game." % id)
	if not _players_spawn_node.has_node(str(id)):
		return
	_players_spawn_node.get_node(str(id)).queue_free()
	
func _end_singleplayer():
	print("ending singleplayer")
	var player_to_remove = get_tree().get_current_scene().get_node("Player")
	player_to_remove.queue_free()

@rpc
func sync_map_seed(mySeed: int):
	map_seed = mySeed
	if !multiplayer.is_server():
		emit_signal("player_joined", multiplayer_mode_enabled)