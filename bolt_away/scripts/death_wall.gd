extends Node2D

var 	death_wall_start = false
var   wall_velocity    = Constants.DeathWall.WALL_INITIAL_VELOCITY
var   playersNode
var   player

func _ready() -> void:
	MultiplayerManager.connect("client_joined", get_players_node)
	if !MultiplayerManager.multiplayer_mode_enabled:
		player = get_tree().get_current_scene().get_node("Player")


func _process(delta: float) -> void:
	if MultiplayerManager.multiplayer_mode_enabled and MultiplayerManager.start_wall:
		multiplayer_algorithm()
		position.x += (wall_velocity * delta)
	else:
		if death_wall_start:
			singleplayer_algorithm()
			position.x += (wall_velocity * delta)
		
		
func singleplayer_algorithm():
	if((player.position.x - position.x ) > Constants.DeathWall.WALL_MAX_DISTANCE):
		position.x += (player.position.x - position.x) - Constants.DeathWall.WALL_MAX_DISTANCE
	else:
		if (wall_velocity <= Constants.DeathWall.WALL_TERMINAL_VELOCITY):
			wall_velocity += Constants.DeathWall.WALL_ACCELERATION
func multiplayer_algorithm():
	if !playersNode:
		get_players_node()
	var distance = 100000
	for playerNode in playersNode:
		if (playerNode.position.x < distance):
			distance = playerNode.position.x
	if(distance - position.x ) > Constants.DeathWall.WALL_MAX_DISTANCE :
		position.x += (distance - position.x) - Constants.WALL_MAX_DISTANCE
	else:
		if(wall_velocity <= Constants.DeathWall.WALL_TERMINAL_VELOCITY):
			wall_velocity += Constants.DeathWall.WALL_ACCELERATION

func get_players_node():
	playersNode = get_tree().get_current_scene().get_node("Players").get_children()
	
			
