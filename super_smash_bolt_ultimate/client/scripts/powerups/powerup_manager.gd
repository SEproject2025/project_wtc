extends Node2D


var current_powerup: Constants.PowerUpType = Constants.PowerUpType.NONE
var jetpack_fuel = 100
var is_jetpack_active = false
var isGrappling: bool = false
var targetPlayer
var grappleTargetPosition: Vector2 
var toPosition: Vector2 # Used to draw other player's grappling hooks
var fromPosition: Vector2 # Used to draw other player's grappling hooks
var drawGrapplingHook: bool = false
var queueRedraw: bool = false
var dashFuel: int = 100
var is_dash_powerup_active: bool = false

@onready var oilspill_scene = preload("res://scenes/powerups/oilspill.tscn")

@export var parent: CharacterBody2D
@export var PowerUpHUD: Control


func _process(_delta: float) -> void:
	if isGrappling:
		queue_redraw()
		draw_grappling_hook.rpc(parent.global_position, grappleTargetPosition)
		if parent.global_position.distance_to(grappleTargetPosition) < 10 or parent.global_position > grappleTargetPosition:
			stop_grappling_hook.rpc()
	if drawGrapplingHook or queueRedraw:
		queueRedraw = false
		queue_redraw()


func _draw() -> void:
	if isGrappling:
		draw_line(parent.PLAYER.CENTER_OF_SPRITE, to_local(grappleTargetPosition), Color.BLACK, 1.5)
	if drawGrapplingHook:
		draw_line(to_local(fromPosition), to_local(toPosition), Color.BLACK, 1.5)

func collect_powerup(powerup: Constants.PowerUpType) -> void:
	if current_powerup == Constants.PowerUpType.NONE and get_multiplayer_authority() == User.ID: 
		current_powerup = powerup
		PowerUpHUD.rpc("update_powerup_icon", powerup)

func use_powerup() -> void:
	match current_powerup:
		Constants.PowerUpType.DASH:
			print("Dash!")
			activate_dash()
		Constants.PowerUpType.JETPACK:
			print("Jetpack!")
			activate_jetpack()
		Constants.PowerUpType.OILSPILL:
			print("Oil spill!")
			throw_oil.rpc()
		Constants.PowerUpType.GRAPPLINGHOOK:
			print("Grappling hook!")
			fire_grappling_hook()
		Constants.PowerUpType.NONE:
			print("No powerup!")
	if not is_jetpack_active:
		PowerUpHUD.rpc("update_powerup_icon", Constants.PowerUpType.NONE)
		current_powerup = Constants.PowerUpType.NONE

#region Dash
func activate_dash() -> void:
	dashFuel = 100
	is_dash_powerup_active = true
		
func deactivate_dash() -> void:
	is_dash_powerup_active = false
	PowerUpHUD.rpc("update_powerup_icon", Constants.PowerUpType.NONE)
	current_powerup = Constants.PowerUpType.NONE
#endregion

#region JetPack	
func activate_jetpack() -> void:
	jetpack_fuel = 100
	is_jetpack_active = true

func deactivate_jetpack() -> void:
	is_jetpack_active = false
	PowerUpHUD.rpc("update_powerup_icon", Constants.PowerUpType.NONE)
	current_powerup = Constants.PowerUpType.NONE
#endregion

#region Oil Spill
@rpc("any_peer","call_local","reliable")
func throw_oil() -> void:
	var oilspill = oilspill_scene.instantiate()
	oilspill.position = parent.global_position + Vector2(67, -10)
	get_tree().get_root().add_child(oilspill)
#endregion


#region Grappling Hook
func fire_grappling_hook():
	isGrappling = true
	targetPlayer = get_leading_player()
	if targetPlayer:
		grappleTargetPosition = targetPlayer.global_position + parent.PLAYER.CENTER_OF_SPRITE
		parent.rayCastRight.look_at(grappleTargetPosition)
		targetPlayer.rpc("begin_pulling_to_target", parent.global_position)
	else:
		if parent.raycastToObstacle.is_colliding():
			grappleTargetPosition = parent.raycastToObstacle.get_collision_point()
	draw_grappling_hook.rpc(parent.global_position, grappleTargetPosition)

func get_leading_player() -> Node2D:
	var closestPlayer = null
	var closestDistance = null

	for player in get_tree().get_nodes_in_group("Players"):
		if player.name != parent.name and player.global_position.x > parent.global_position.x:
			var distance = parent.global_position.distance_to(player.global_position)
			if !closestDistance or distance < closestDistance:
				closestDistance = distance
				closestPlayer = player

	return closestPlayer

@rpc("any_peer","call_local","reliable")
func stop_grappling_hook():
	isGrappling = false
	drawGrapplingHook = false
	targetPlayer = null
	queueRedraw = true
	grappleTargetPosition = Vector2.ZERO
	fromPosition = Vector2.ZERO


@rpc("any_peer", "call_remote" , "reliable")
func draw_grappling_hook(throwerPosition: Vector2, targetPosition: Vector2):
	if !drawGrapplingHook:
		drawGrapplingHook = true
	toPosition = targetPosition
	fromPosition = throwerPosition + parent.PLAYER.CENTER_OF_SPRITE

#endregion
