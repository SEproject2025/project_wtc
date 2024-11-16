extends Node2D

const WALL_TERMINAL_VELOCITY := 150.0
const WALL_INITIAL_VELOCITY  := 25.0
const WALL_ACCELERATION      := 0.02

var   wall_velocity          = WALL_INITIAL_VELOCITY
@onready var gameManager = get_tree().get_current_scene().get_node("GameManager")

func _process(delta: float) -> void:
	if MultiplayerManager.multiplayer_mode_enabled and MultiplayerManager.start_wall:
		position.x += (wall_velocity * delta)
		if(wall_velocity <= WALL_TERMINAL_VELOCITY):
			wall_velocity += WALL_ACCELERATION

	if gameManager.singlePlayerEnabled:
		position.x += (wall_velocity * delta)
		if(wall_velocity <= WALL_TERMINAL_VELOCITY):
			wall_velocity += WALL_ACCELERATION