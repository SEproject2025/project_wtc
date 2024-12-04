extends Node

@export var powerup_type: Constants.PowerUpType

func on_entered(body):
	if body.name == "Player" || body is MultiplayerPlayer:
		body.powerupManager.collect_powerup(powerup_type)
		queue_free()
