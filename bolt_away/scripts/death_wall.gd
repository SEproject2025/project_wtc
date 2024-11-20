extends Node2D

const WALL_TERMINAL_VELOCITY := 150.0
const WALL_INITIAL_VELOCITY  := 70.0
const WALL_ACCELERATION      := 0.002
const WALL_MAX_DISTANCE      := 400

var death_wall_start = false
var   wall_velocity          = WALL_INITIAL_VELOCITY

func _process(delta: float) -> void:
	if MultiplayerManager.multiplayer_mode_enabled and MultiplayerManager.start_wall:
		multiplayer_algorithm()
		position.x += (wall_velocity * delta)
		print("yeet", wall_velocity)
	else:
		if death_wall_start:
			singleplayer_algorithm()
			position.x += (wall_velocity * delta)
			print("yote", wall_velocity)
		
		
func singleplayer_algorithm():
	
	var player = get_parent().get_node("Player")
	if((player.position.x - position.x ) > WALL_MAX_DISTANCE):
		position.x += (player.position.x - position.x) - WALL_MAX_DISTANCE
	else:
		if (wall_velocity <= WALL_TERMINAL_VELOCITY):
			wall_velocity += WALL_ACCELERATION
func multiplayer_algorithm():
	var playersNode = get_tree().get_current_scene().get_node("Players").get_children()
	var distance = 100000
	for playerNode in playersNode:
		if (playerNode.position.x < distance):
			distance = playerNode.position.x
	if(distance - position.x ) > WALL_MAX_DISTANCE :
		position.x += (distance - position.x) - WALL_MAX_DISTANCE
	else:
		if(wall_velocity <= WALL_TERMINAL_VELOCITY):
			wall_velocity += WALL_ACCELERATION
			
