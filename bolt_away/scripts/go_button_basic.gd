extends Button

var game_countdown_iteration = 3

@onready var game_start_timer: Timer = $"../game_start_timer"

func _on_pressed() -> void:
	$".".set_visible(false)
	$"../countdown_display".set_visible(true)
	game_start_timer.start()
	print("Game Starting")

func _on_game_start_timer_timeout() -> void:
	if game_countdown_iteration >= 1:
		$"../countdown_display".text = str(game_countdown_iteration)
	elif game_countdown_iteration == 0:
		$"../countdown_display".text = "GOOOOO!!!!!!"
	else:
		$"../countdown_display".set_visible(false)
		$"..".queue_free
		game_start_timer.stop()	
	game_countdown_iteration -= 1;
