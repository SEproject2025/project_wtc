extends Area2D

@onready var timer = $Timer

func _on_body_entered(body):
	if not MultiplayerManager.multiplayer_mode_enabled:
		print("player died")
		Engine.time_scale = 0.5
		body.get_node("CollisionShape2D").queue_free()
		timer.start()
	else:
		_dead_multiplayer(body)

func _dead_multiplayer(body):
	if body.alive:
		body.set_dead()

func _on_timer_timeout():
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()
