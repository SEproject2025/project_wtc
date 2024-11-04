extends Area2D

const SPEED = 400
const MAX_DISTANCE = 400

var throwerName: String
var throwerPosition: Vector2
var direction: Vector2
var flip_h: bool
var targetPlayer: Node2D
var thrower: Node2D

@onready var navAgent = $NavigationAgent2D
@onready var sprite2D = $Sprite2D
@onready var navAgentTimer = $NavAgentTimer


func _ready() -> void:
	position = throwerPosition

	#only for placeholder purposes; change when final design is done
	sprite2D.flip_h = flip_h
	sprite2D.flip_v = flip_h
	targetPlayer = find_closest_player()
	if targetPlayer:
		navAgent.set_target_position(targetPlayer.global_position)

func _physics_process(delta: float) -> void:
	if navAgent.is_navigation_finished():
		queue_free()
		return
	var nextPosition = navAgent.get_next_path_position()
	var directionToNext = (nextPosition - global_position).normalized()
	position += directionToNext * SPEED * delta



func _on_body_entered(body: Node2D) -> void:
	if body is MultiplayerPlayer and body.name != throwerName:
		if thrower:
			thrower.pull_to_target(body.global_position)
		if multiplayer.get_unique_id() != body.name.to_int():
			MultiplayerManager.rpc_id(body.name.to_int(), "pull_to_target", throwerPosition)
		queue_free()


func find_closest_player() -> Node2D:
	var closestPlayer = null
	var closestDistance = null

	for player in get_tree().get_current_scene().get_node("Players").get_children():
		if player.name != throwerName and player.global_position.x > global_position.x:
			var distance = global_position.distance_to(player.global_position)
			if !closestDistance or distance < closestDistance:
				closestDistance = distance
				closestPlayer = player

	return closestPlayer

func updatePath():
	navAgent.set_target_position(targetPlayer.global_position)