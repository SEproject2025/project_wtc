extends Control

var lobby_menu_template = preload("res://scenes/lobby_menu.tscn")
var pop_up_template = preload("res://scenes/pop_up.tscn")
var main_menu_template = preload("res://scenes/main_menu.tscn")
var control_flag : bool = false
var lobby_menu

func _ready() -> void:
	name = "main_menu"

func _on_play_pressed():
	if get_child_count() > 5:
		return
	if control_flag:
		return
	
	var user_text = $VBoxContainer/Username.text
	
	if user_text == "" or user_text.contains(" "):
		var pop_up = pop_up_template.instantiate()
		pop_up.set_msg("Enter a name!\nNo spaces are allowed!")
		add_child(pop_up)
		return
	else:
		if User.client:
			User.client.queue_free()
		User.client = Client.new()
		get_parent().add_child(User.client)
		control_flag = true
		User.client.user_name_feedback_received.connect(go_to_lobby_menu)
		User.client.invalid_user_name.connect(invalid_name)
		$Loading.show()
		await get_tree().create_timer(2).timeout
		
		if User.client.is_connection_valid():
			lobby_menu = lobby_menu_template.instantiate()
			User.client.request_lobby_list()
			User.client.send_user_name($VBoxContainer/Username.text)
	
	
	check_if_connected()

func check_if_connected():
	await get_tree().create_timer(2).timeout
	
	if User.client.is_client_connected():
		$Loading.hide()
		return
	else:
		if lobby_menu:
			lobby_menu.queue_free()
		control_flag = false
		$Loading.hide()
		$"Cannot Connect".show()
		await get_tree().create_timer(1).timeout
		$"Cannot Connect".hide()
	
	$Loading.hide()

func go_to_lobby_menu():
	User.after_main_menu_init()
	$Loading.hide()
	$Connected.show()
	await get_tree().create_timer(1).timeout
	get_parent().add_child(lobby_menu)
	queue_free()

func _on_username_text_submitted(_new_text):
	_on_play_pressed()

func _on_quit_pressed():
	get_tree().quit(0)

func invalid_name():
	var new_main_menu = main_menu_template.instantiate()
	get_parent().add_child(new_main_menu)
	var pop_up = pop_up_template.instantiate()
	pop_up.set_msg("Invalid name!")
	new_main_menu.add_child(pop_up)
	queue_free()
