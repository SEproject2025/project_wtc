extends RigidBody2D

@onready var rayCast = $RayCast2D
@onready var timer = $Timer


func _ready() -> void:
	apply_central_impulse(Vector2(200, 0))

func _physics_process(_delta):
	if rayCast.is_colliding():
		freeze = true

func on_entered(body):
	print("entered")
	if body.is_in_group("Players"):
		body.oil_slip()
	

func _on_timer_timeout() -> void:
	queue_free()