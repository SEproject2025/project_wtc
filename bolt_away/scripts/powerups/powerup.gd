extends Node

const PowerUpType = preload("res://scripts/powerup_manager.gd").PowerUpType

@export var powerup_type: PowerUpType

func on_entered(body):
	if body.name == "Player" || body is MultiplayerPlayer:
		body.get_node("PowerUpManager").collect_powerup(powerup_type)
		queue_free()
