extends Area2D

@onready var timer = $Timer

func _on_body_entered(body):
	if not MultiplayerManager.multiplayer_mode_enabled:
		print("player died")
		Engine.time_scale = 0.5
		body.get_node("CollisionShape2D").queue_free()
		timer.start()
		end_singleplayer()
	else:
		_dead_multiplayer(body)

func _dead_multiplayer(body):
	if body.alive:
		body.set_dead()
		MultiplayerManager._end_game(body.player_id)

func _on_timer_timeout():
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()

func end_singleplayer():
	var end_screen = get_tree().get_current_scene().get_node("EndGameScreen")
	var label = end_screen.get_node("Message")
	label.text = "You Lost!"
	end_screen.show()
	get_tree().paused = true



	
