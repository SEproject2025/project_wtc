extends Control

var main_menu = preload("res://scenes/main_menu.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	if OS.is_debug_build():
		return
	$Video.play()
	$Video.finished.connect(end)

func _input(event):
	if (event is InputEventKey and event.is_pressed()) or (event is InputEventMouseButton and event.pressed):
		$Video.stop()
		if !get_parent().has_node("main_menu"):
			get_parent().add_child(main_menu.instantiate())
		queue_free()

func end():
	get_parent().add_child(main_menu.instantiate())
	queue_free()
