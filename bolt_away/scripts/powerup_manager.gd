extends Node


var current_powerup: Constants.PowerUpType = Constants.PowerUpType.NONE
var jetpack_fuel = 100
var is_jetpack_active = false

@onready var oilspill_scene = preload("res://scenes/powerups/oilspill.tscn")

@export var parent: CharacterBody2D
@export var PowerUpHUD: Control

func collect_powerup(powerup: Constants.PowerUpType) -> void:
	if current_powerup == Constants.PowerUpType.NONE:
		current_powerup = powerup
	PowerUpHUD.update_powerup_icon(powerup)

func use_powerup() -> void:
	match current_powerup:
		Constants.PowerUpType.DASH:
			print("Dash!")
			parent.start_dash()
		Constants.PowerUpType.JETPACK:
			print("Jetpack!")
			activate_jetpack()
		Constants.PowerUpType.OILSPILL:
			print("Oil spill!")
			throw_oil()
		Constants.PowerUpType.GRAPPLINGHOOK:
			print("Grappling hook!")
			parent.fire_grappling_hook()
		Constants.PowerUpType.NONE:
			print("No powerup!")
	current_powerup = Constants.PowerUpType.NONE
	if not is_jetpack_active:
		PowerUpHUD.update_powerup_icon(Constants.PowerUpType.NONE)

#TODO: Can pick up another powerup while jetpack is active
func activate_jetpack() -> void:
	jetpack_fuel = 100
	is_jetpack_active = true

func deactivate_jetpack() -> void:
	is_jetpack_active = false
	PowerUpHUD.update_powerup_icon(Constants.PowerUpType.NONE)

func throw_oil() -> void:
	var oilspill = oilspill_scene.instantiate()
	oilspill.position = parent.global_position + Vector2(64, 0)
	get_tree().get_root().add_child(oilspill)
	if MultiplayerManager.multiplayer_mode_enabled:
		MultiplayerManager.rpc("spawn_oilspill", oilspill.position)
