extends Area2D

const SPEED = 400
const MAX_DISTANCE = 400
const PULL_FORCE = 50

var isHooked: bool = false
var initialPosition: Vector2
var throwerName
var direction: Vector2
var flip_h: bool

@onready var sprite2D = $Sprite2D


func _ready() -> void:
	initialPosition = global_position

	#only for placeholder purposes; change when final design is done
	sprite2D.flip_h = flip_h
	sprite2D.flip_v = flip_h

func _physics_process(delta: float) -> void:
	if !isHooked:
		position.x += SPEED * delta * direction.x

		if global_position.distance_to(initialPosition) >= MAX_DISTANCE:
			queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body is MultiplayerPlayer and body.name != throwerName and !isHooked:
		isHooked = true
		body.pull_to_target(initialPosition)
		if multiplayer.get_unique_id() != body.name.to_int():
			MultiplayerManager.rpc_id(body.name.to_int(), "pull_to_target", initialPosition)
		queue_free()
