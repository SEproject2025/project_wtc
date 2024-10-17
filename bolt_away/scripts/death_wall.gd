extends Node2D

const WALL_TERMINAL_VELOCITY := 150.0
const WALL_INITIAL_VELOCITY  := 25.0
const WALL_ACCELERATION      := 0.02

var   wall_velocity          = WALL_INITIAL_VELOCITY
var should_move_wall         = false
func _ready() -> void:
	MultiplayerManager.connect("player_joined", player_joined)

func _process(delta: float) -> void:
	if MultiplayerManager.start_wall:
		if MultiplayerManager.multiplayer_mode_enabled:
			multiplayer_algorithm(delta)
		else:
			singleplayer_algorithm(delta)


func singleplayer_algorithm(delta: float) -> void:
	position.x += (wall_velocity * delta)
	if(wall_velocity <= WALL_TERMINAL_VELOCITY):
		wall_velocity += WALL_ACCELERATION

func multiplayer_algorithm(delta: float) -> void:
	if MultiplayerManager.start_wall:
		position.x += (wall_velocity * delta)
		if(wall_velocity <= WALL_TERMINAL_VELOCITY):
			wall_velocity += WALL_ACCELERATION

func player_joined(_multiplayer_mode_enabled) -> void:
	if !multiplayer.is_server():
		MultiplayerManager.rpc("start_death_wall")
	MultiplayerManager.start_wall = true
