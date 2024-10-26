extends Node

enum PowerUpType {
	NONE,
	DASH,
	JETPACK,
	OILSPILL
}

var current_powerup: PowerUpType = PowerUpType.NONE

func collect_powerup(powerup: PowerUpType) -> void:
	if current_powerup == PowerUpType.NONE:
		current_powerup = powerup
		print("Collected powerup!")
	else:
		print("Already have a powerup!")

func use_powerup() -> void:
	match current_powerup:
		PowerUpType.DASH:
			print("Dash!")
		PowerUpType.JETPACK:
			print("Jetpack!")
		PowerUpType.OILSPILL:
			print("Oil spill!")
		PowerUpType.NONE:
			print("No powerup!")
	current_powerup = PowerUpType.NONE



