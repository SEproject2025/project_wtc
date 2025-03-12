extends Node2D

const WALL_TERMINAL_VELOCITY := 150.0
const WALL_INITIAL_VELOCITY  := 70.0
const WALL_ACCELERATION      := 0.002
const WALL_MAX_DISTANCE      := 400

var death_wall_start = false
var   wall_velocity          = WALL_INITIAL_VELOCITY

func _process(delta: float) -> void:
	pass
	# if death_wall_start:
	# 	var players = get_tree().get_nodes_in_group("Players")
	# 	var distance = 100000
	# 	for player in players:
	# 		if (player.position.x < distance):
	# 			distance = player.position.x
	# 	if(distance - position.x ) > WALL_MAX_DISTANCE :
	# 		position.x += (distance - position.x) - WALL_MAX_DISTANCE
	# 	else:
	# 		if(wall_velocity <= WALL_TERMINAL_VELOCITY):
	# 			wall_velocity += WALL_ACCELERATION
	# 	position.x += (wall_velocity * delta)
		
func singleplayer_algorithm():
	var player = get_parent().get_node("Player")
	if((player.position.x - position.x ) > WALL_MAX_DISTANCE):
		position.x += (player.position.x - position.x) - WALL_MAX_DISTANCE
	else:
		if (wall_velocity <= WALL_TERMINAL_VELOCITY):
			wall_velocity += WALL_ACCELERATION
