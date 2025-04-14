extends CanvasLayer

@onready var active = $Active
@onready var inactive = $Inactive

func update_active_icon(powerup_type: Constants.PowerUpType):
	if Constants.powerupIcons.has(Constants.PowerUpType.keys()[powerup_type]):
		active.get_node("Icon").texture = Constants.powerupIcons[Constants.PowerUpType.keys()[powerup_type]]
	else:
		active.get_node("Icon").texture = null

func update_inactive_icon(powerup_type: Constants.PowerUpType):
	if Constants.powerupIcons.has(Constants.PowerUpType.keys()[powerup_type]):
		inactive.get_node("Icon").texture = Constants.powerupIcons[Constants.PowerUpType.keys()[powerup_type]]
	else:
		inactive.get_node("Icon").texture = null
