extends Control

const PowerUpType = preload("res://scripts/powerup_manager.gd").PowerUpType

const powerupIcons: Dictionary = {
	"DASH": preload("res://assets/powerups (placeholders)/dash_icon.png"),
	"JETPACK": preload("res://assets/powerups (placeholders)/jetpack_icon.png"),	
	"OILSPILL": preload("res://assets/powerups (placeholders)/oilspill_icon.png"),
	"GRAPPLINGHOOK": preload("res://assets/powerups (placeholders)/grapplinghook_icon.png"),
}


@onready var powerupIcon = $PowerupIcon

func update_powerup_icon(powerup_type: PowerUpType):
	if powerupIcons.has(PowerUpType.keys()[powerup_type]):
		powerupIcon.texture = powerupIcons[PowerUpType.keys()[powerup_type]]
	else:
		powerupIcon.texture = null
