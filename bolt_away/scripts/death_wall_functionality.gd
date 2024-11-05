extends Node2D
const WALL_TERMINAL_VELOCITY := 0.0
const WALL_INITIAL_VELOCITY  := 0.0
const WALL_ACCELERATION      := 0.002

var   wall_velocity           = WALL_INITIAL_VELOCITY
func _process(delta: float) -> void:
	if !MultiplayerManager.multiplayer_mode_enabled:
		singleplayer_algorithm()
	else:
		multiplayer_algorithm()
	position.x += (wall_velocity * delta)
		
func singleplayer_algorithm():
	
	var player = get_parent().get_node("Player")
	if((player.position.x - position.x ) > 300):
		position.x += (player.position.x - position.x) - 300
	else:
		if (wall_velocity <= WALL_TERMINAL_VELOCITY):
			wall_velocity += WALL_ACCELERATION
func multiplayer_algorithm():
	var playersNode = get_tree().get_current_scene().get_node("Players").get_children()
	var distance = 100000
	for playerNode in playersNode:
		if (playerNode.position.x < distance):
			distance = playerNode.position.x
	if(distance - position.x ) > 100 :
		position.x += (distance - position.x) - 100
	else:
		if (wall_velocity <= WALL_TERMINAL_VELOCITY):
				wall_velocity += WALL_ACCELERATION
	
