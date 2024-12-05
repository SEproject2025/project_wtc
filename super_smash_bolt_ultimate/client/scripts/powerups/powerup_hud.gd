extends Control

@onready var powerupIcon = $PowerupIcon

@rpc ("any_peer", "call_local", "reliable")
func update_powerup_icon(powerup_type: Constants.PowerUpType):
	if Constants.powerupIcons.has(Constants.PowerUpType.keys()[powerup_type]):
		powerupIcon.texture = Constants.powerupIcons[Constants.PowerUpType.keys()[powerup_type]]
	else:
		powerupIcon.texture = null
