extends Area2D

const SPEED = 400
const MAX_DISTANCE = 400
const PULL_FORCE = 50

var isHooked = false
var initialPosition: Vector2
var thrower: CharacterBody2D


func _ready() -> void:
	initialPosition = global_position

func _physics_process(delta: float) -> void:
	if !isHooked:
		position.x += SPEED * delta

		if global_position.distance_to(initialPosition) >= MAX_DISTANCE:
			queue_free()
	else:
		if thrower.global_position.distance_to(position) < 20:
			queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body is MultiplayerPlayer and body != thrower and !isHooked:
		isHooked = true
		body.pull_to_target(thrower.global_position)
		MultiplayerManager.rpc_id(body.name.to_int(), "pull_to_target", thrower.global_position)