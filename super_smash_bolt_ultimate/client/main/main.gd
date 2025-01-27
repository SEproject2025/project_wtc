extends Node

var pop_up_template = preload("res://scenes/pop_up.tscn")
var intro_template = preload("res://scenes/intro.tscn")
var main_menu = preload("res://scenes/main_menu.tscn")

func _ready():
	var intro = intro_template.instantiate()
	add_child(intro)
	User.reset.connect(connection_reset)

func _process(_delta):
	pass

func connection_reset():
	for i in get_children():
		i.queue_free()
	add_child(main_menu.instantiate())
	var pop_up = pop_up_template.instantiate()
	pop_up.set_msg("connection lost!", Color(255, 255, 255))
	add_child(pop_up)
