extends Control

func set_msg(_msg : String, \
_color : Color = Color(255, 255, 255)):
	$VBoxContainer/Detail.text = _msg
	$VBoxContainer/Detail.add_theme_color_override("font_color", _color)


func is_button_visible(is_visible : bool):
	if not is_visible:
		$VBoxContainer/Close.hide()

func _on_close_pressed():
	queue_free()
