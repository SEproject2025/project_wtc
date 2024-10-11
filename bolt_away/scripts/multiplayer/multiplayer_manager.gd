extends Node

const SERVER_PORT = 8080
const SERVER_IP = "127.0.0.1"

var multiplayer_scene = preload("res://scenes/multiplayer_player.tscn")
var font = preload("res://assets/fonts/monogram.ttf")


var _players_spawn_node
var host_mode_enabled = false	
var multiplayer_mode_enabled = false
var respawn_point = Vector2(30, 20)
var map_seed = 0
var dead_player_id

signal multiplayer_mode_changed(_multiplayer_mode_enabled: bool)
signal player_joined(_multiplayer_mode_enabled: bool)

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
	
func _end_game(losing_player_id):
	sync_losing_player_id(losing_player_id)
	_game_ended(losing_player_id)

@rpc
func sync_losing_player_id(losing_player_id: int):
	dead_player_id = losing_player_id
	if multiplayer.is_server():
		print("Server's player died:" + str(dead_player_id))
	else:
		print("Client's player died:" + str(dead_player_id))

func _game_ended(losing_player_id: int):
	if multiplayer.get_unique_id() == losing_player_id:
		print("You lost!")
		_show_winning_message("You lost!")
	else:
		print("You won!")
		_show_winning_message("You won!") 

	get_tree().paused = true

func _show_winning_message(message: String):
	var canvas_layer = CanvasLayer.new()

	get_tree().get_root().add_child(canvas_layer)

	var message_label = Label.new()
	message_label.text = message
	message_label.add_theme_color_override("font_color", Color.RED)
	message_label.add_theme_font_override("font", font)
	message_label.add_theme_font_size_override("font_size", 50)	

	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.set_anchors_preset(Control.PRESET_CENTER)
	
	canvas_layer.add_child(message_label)

@rpc
func sync_map_seed(mySeed: int):
	map_seed = mySeed
	if !multiplayer.is_server():
		emit_signal("player_joined", multiplayer_mode_enabled)
