extends Control


func _ready() -> void:
	#Skip main menu if debugging
	if OS.is_debug_build():
		get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_host_pressed():
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_join_pressed():
	pass # Replace with function body.


func _on_tutorial_pressed():
	pass # Replace with function body.


func _on_exit_pressed():
	get_tree().quit()
