extends Node2D

const WALL_TERMINAL_VELOCITY := 150.0
const WALL_INITIAL_VELOCITY  := 25.0
const WALL_ACCELERATION      := 0.02

var   wall_velocity           = WALL_INITIAL_VELOCITY
func _process(delta: float) -> void:
	position.x += (wall_velocity * delta)
	if(wall_velocity <= WALL_TERMINAL_VELOCITY):
		wall_velocity += WALL_ACCELERATION
