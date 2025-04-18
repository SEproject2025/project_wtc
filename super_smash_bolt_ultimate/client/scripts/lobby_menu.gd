extends Control

var pop_up_template = preload("res://scenes/pop_up.tscn")
var main_menu_template = preload("res://scenes/main_menu.tscn")
var in_lobby_menu_template = preload("res://scenes/in_lobby_menu.tscn")
		
func _init():
	User.client.lobby_list_received.connect(create_lobby_list)
	User.client.invalid_new_lobby_name.connect(invalid_new_lobby_name)
	User.client.invalid_join_lobby_name.connect(invalid_join_lobby_name)
	User.client.join_lobby.connect(_join_lobby)
	User.client.new_lobby.connect(_new_lobby)

func invalid_join_lobby_name():
	var pop_up = pop_up_template.instantiate()
	pop_up.set_msg("   this lobby doesn't exist...\ntry refreshing",\
	 Color(255, 255, 255))
	pop_up.is_button_visible(false)
	add_child(pop_up)
	await get_tree().create_timer(1).timeout
	pop_up.queue_free()

func _join_lobby(lobby_info : String):
	var arr = lobby_info.split("***")
	var lobby_name = arr[0]
	var pop_up = pop_up_template.instantiate()
	pop_up.set_msg("   joining lobby...")
	pop_up.is_button_visible(false)
	add_child(pop_up)
	User.current_lobby_name = lobby_name
	User.current_lobby_state = arr[1].to_int() as Constants.LobbyState
	print("joined lobby %s !" %lobby_name)
	get_parent().add_child(in_lobby_menu_template.instantiate())
	queue_free()

func _new_lobby(lobby_name : String):
	var pop_up = pop_up_template.instantiate()
	pop_up.set_msg("   creating a new lobby...")
	pop_up.is_button_visible(false)
	add_child(pop_up)
	User.is_host = true
	User.current_lobby_name = lobby_name
	print("new lobby created %s !" %lobby_name)
	get_parent().add_child(in_lobby_menu_template.instantiate())
	queue_free()

func invalid_new_lobby_name():
		var pop_up = pop_up_template.instantiate()
		pop_up.set_msg("lobby name taken!")
		add_child(pop_up)

func create_lobby_list(lobby_list : PackedStringArray):
	if lobby_list.is_empty():
		var pop_up = pop_up_template.instantiate()
		pop_up.set_msg("no lobby exists :(\ncreate one!")
		add_child(pop_up)
	
	
	var container = $VBoxContainer/ScrollContainer/VBoxContainer
	for i in container.get_children():
		if i != null:
			i.queue_free()
	for i in lobby_list:
		var lobby_list_label = $Lobby_template.duplicate()
		lobby_list_label.show()
		lobby_list_label.get_child(0).text = i
		lobby_list_label.get_child(1).pressed.connect(_on_join_lobby_pressed.bind(lobby_list_label.get_child(0).text))
		container.add_child(lobby_list_label)

func _on_join_lobby_pressed(_lobby_name : String):
	User.client.request_join_lobby(_lobby_name)

func _on_new_lobby_pressed():
	var lobby_name : String = $Lobby_name.text
	if lobby_name == "" or lobby_name.contains(" "):
		var pop_up = pop_up_template.instantiate()
		pop_up.set_msg("Enter the lobby name!\nNo spaces are allowed!")
		add_child(pop_up)
	else:
		User.client.request_new_lobby(lobby_name)

func _on_return_pressed():
	get_parent().add_child(load("res://scenes/main_menu.tscn").instantiate())
	User.reset_connection()
	queue_free()

func _on_refresh_pressed():
	User.client.request_lobby_list()


func _on_lobby_name_text_submitted(new_text):
	_on_new_lobby_pressed()
