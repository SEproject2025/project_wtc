extends Node2D

const WALL_TERMINAL_VELOCITY := 150.0
const WALL_INITIAL_VELOCITY  := 70.0
const WALL_ACCELERATION      := 0.002

var   wall_velocity          = WALL_INITIAL_VELOCITY
var   playersNode

func _ready() -> void:
	MultiplayerManager.connect("client_joined", get_player_node)

func _process(delta: float) -> void:
	if MultiplayerManager.multiplayer_mode_enabled and MultiplayerManager.start_wall:
		if !playersNode:
			get_player_node()
		var distance = 100000
		for playerNode in playersNode:
			if (playerNode.position.x < distance):
				distance = playerNode.position.x
		if(distance - position.x ) > 400 :
			position.x += (distance - position.x) - 400
		else:
			position.x += (wall_velocity * delta)
			if (wall_velocity <= WALL_TERMINAL_VELOCITY):
				wall_velocity += WALL_ACCELERATION

func get_player_node():
	playersNode = get_tree().get_current_scene().get_node("Players").get_children()
