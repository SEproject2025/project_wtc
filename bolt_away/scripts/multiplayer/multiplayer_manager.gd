extends Node

const SERVER_PORT = 8080
const SERVER_IP = "10.100.74.78"
const PLAYERS_TO_START_GAME = 2

var multiplayer_scene = preload("res://scenes/multiplayer_player.tscn")
var oilspill_scene = preload("res://scenes/powerups/oilspill.tscn")

var _players_spawn_node 
var host_mode_enabled:  = false	
var multiplayer_mode_enabled: bool = false
var respawn_point = Vector2(30, 20)
var map_seed = 0
var dead_player_id = 0
var start_wall: bool = false
var isBeingPulled: bool = false
var pull_target_position = Vector2(0, 0)
var grappleTargetPosition: Vector2
var grappleThrowerPosition: Vector2
var drawGrapplingHook: bool = false
var redraw_queue: bool = false

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

	if !multiplayer.is_server() or !OS.has_feature("dedicated_server"):
		_clean_multiplayer_state()

	
func _end_singleplayer():
	print("ending singleplayer")
	var player_to_remove = get_tree().get_current_scene().get_node("Player")
	player_to_remove.queue_free()
	
func _end_game(losing_player_id):
	if multiplayer.is_server():
		dead_player_id = losing_player_id
		rpc("sync_losing_player_id", dead_player_id)
		if !OS.has_feature("dedicated_server"):
			_show_end_message(losing_player_id)
		else:
			reset_dedicated_server_state()

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

func reset_dedicated_server_state():
	var deathWall = get_tree().get_current_scene().get_node("DeathWallNode")
	map_seed = 0
	dead_player_id = 0
	start_wall = false
	deathWall.position.x = Constants.DeathWall.START_X 
	deathWall.wall_velocity = Constants.DeathWall.WALL_INITIAL_VELOCITY

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
	var deathWall = get_tree().get_current_scene().get_node("DeathWallNode")
	start_wall = true
	deathWall.position.x = Constants.DeathWall.START_X
	deathWall.wall_velocity = Constants.DeathWall.WALL_INITIAL_VELOCITY

@rpc("any_peer")
func spawn_oilspill(position: Vector2):
	var oilspill = oilspill_scene.instantiate()
	oilspill.position = position
	get_tree().get_root().add_child(oilspill)

@rpc("any_peer")
func pull_to_target(targetPosition: Vector2):
	isBeingPulled = true
	pull_target_position = targetPosition + Constants.Player.CENTER_OF_SPRITE

@rpc("any_peer")
func draw_grappling_hook(throwerPosition: Vector2, targetPosition: Vector2):
	drawGrapplingHook = true
	grappleThrowerPosition = throwerPosition + Constants.Player.CENTER_OF_SPRITE
	grappleTargetPosition = targetPosition

@rpc("any_peer")
func update_grappling_hook(throwerPosition: Vector2, targetPosition: Vector2):
	grappleThrowerPosition = throwerPosition + Constants.Player.CENTER_OF_SPRITE
	grappleTargetPosition = targetPosition

@rpc("any_peer")
func stop_grappling_hook():
	drawGrapplingHook = false
	redraw_queue = true
	grappleTargetPosition = Vector2.ZERO
	grappleThrowerPosition = Vector2.ZERO + Constants.Player.CENTER_OF_SPRITE
