extends CanvasLayer


func _on_pause_pressed():
	if $QuitButton.is_visible():
		$QuitButton.set_visible(false)
		$ContinueButton.set_visible(false)
	else:
		$QuitButton.set_visible(true)
		$ContinueButton.set_visible(true)
	pass # Replace with function body.



func _on_quit_button_pressed():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	pass # Replace with function body.
