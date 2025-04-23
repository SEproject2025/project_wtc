extends CanvasLayer

var main_menu_template = preload("res://scenes/main_menu.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			_on_pause_pressed()

func _on_pause_pressed():
	get_tree().paused = !get_tree().paused
	$Pause.visible = !$Pause.visible
	$ColorRect.visible = !$ColorRect.visible
	$VBoxContainer.visible = !$VBoxContainer.visible
	$VBoxContainer/RestartContainer/RestartButton.grab_focus()

func _on_quit_button_pressed():
	get_tree().paused = false
	get_tree().get_root().get_node("main").add_child(load("res://scenes/main_menu.tscn").instantiate())
	get_tree().get_root().get_node("tutorial").queue_free()


func _on_pause_focus_entered():
	$Pause.release_focus()

func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	$Pause.visible = !$Pause.visible
	$ColorRect.visible = !$ColorRect.visible
	$VBoxContainer.visible = !$VBoxContainer.visible
	get_tree().get_root().get_node("tutorial").get_node("Test Player Character").reset()
