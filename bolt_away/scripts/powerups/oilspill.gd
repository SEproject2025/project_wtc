extends RigidBody2D

@onready var rayCast = $RayCast2D
@onready var timer = $Timer


func _physics_process(delta):
	linear_velocity.x = 200
	if rayCast.is_colliding():
		freeze = true

func on_entered(body):
	print("entered")
	if body.name == "Player" || body is MultiplayerPlayer:
		body.oil_slip()



func _on_timer_timeout() -> void:
	queue_free()
