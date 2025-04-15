extends CanvasLayer

var main_menu_template = preload("res://scenes/main_menu.tscn")

func _on_pause_pressed():
	if $QuitButton.is_visible():
		$QuitButton.set_visible(false)
		$ContinueButton.set_visible(false)
	else:
		$QuitButton.set_visible(true)
		$ContinueButton.set_visible(true)
	pass # Replace with function body.



func _on_quit_button_pressed():
	get_tree().get_root().get_node("main").add_child(load("res://scenes/main_menu.tscn").instantiate())
	get_tree().get_root().get_node("tutorial").queue_free()
