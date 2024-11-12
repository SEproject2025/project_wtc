extends Node

enum PowerUpType {
	NONE,
	DASH,
	JETPACK,
	OILSPILL,
	GRAPPLINGHOOK,
}

var current_powerup: PowerUpType = PowerUpType.NONE
var jetpack_fuel = 100
var is_jetpack_active = false
@onready var oilspill_scene = preload("res://scenes/powerups/oilspill.tscn")
@onready var parent = get_parent()

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
			parent.start_dash()
		PowerUpType.JETPACK:
			print("Jetpack!")
			activate_jetpack()
		PowerUpType.OILSPILL:
			print("Oil spill!")
			throw_oil()
		PowerUpType.GRAPPLINGHOOK:
			print("Grappling hook!")
			parent.fire_grappling_hook()
		PowerUpType.NONE:
			print("No powerup!")
	current_powerup = PowerUpType.NONE


func activate_jetpack() -> void:
	jetpack_fuel = 100
	is_jetpack_active = true

func deactivate_jetpack() -> void:
	is_jetpack_active = false

func throw_oil() -> void:
	var oilspill = oilspill_scene.instantiate()
	oilspill.position = parent.global_position + Vector2(64, 0)
	get_tree().get_root().add_child(oilspill)
	if MultiplayerManager.multiplayer_mode_enabled:
		MultiplayerManager.rpc("spawn_oilspill", oilspill.position)
