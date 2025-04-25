extends Control

var game_scene_template = preload("res://scenes/game_scene.tscn")
var player_character_template = preload("res://scenes/player_character.tscn")
var lobby_menu_template = preload("res://scenes/lobby_menu.tscn")
var pop_up_template = preload("res://scenes/pop_up.tscn")
var main_menu_template = preload("res://scenes/main_menu.tscn")
var tutorial_template = preload("res://scenes/tutorial.tscn")
var tutorial_player_template = preload("res://scenes/tutorial_player_character.tscn")
var control_flag : bool = false
var lobby_menu
var bot_color = 1

func _ready() -> void:
	name = "main_menu"
	$Background/AnimatedBot/AnimationTree.get("parameters/playback").travel("fall_end")
	$Background/AnimatedBot.set_color(User.player_color)
	bot_color = User.player_color

func go_to_lobby_menu():
	User.after_main_menu_init()
	$Loading.hide()
	$Connected.show()
	await get_tree().create_timer(1).timeout
	get_parent().add_child(lobby_menu)
	queue_free()

func _on_username_text_submitted(_new_text:):
	if get_child_count() > 5:
		pass
	if control_flag:
		return

	var user_text = $Title_Screen/Username.text

	var regex = RegEx.new()
	var error = regex.compile("^[A-Za-z0-9]{1,2}$") # Compile the pattern

	if error != OK:
		printerr("Regex compilation failed!")
		var pop_up = pop_up_template.instantiate()
		pop_up.set_msg("An internal error occurred.\nPlease try again.")
		add_child(pop_up)
		return

	var match = regex.search(user_text)

	if match == null:
		var pop_up = pop_up_template.instantiate()
		pop_up.set_msg("Invalid Name!\nMust be 1 or 2 letters/numbers.\nNo spaces or symbols.")
		add_child(pop_up)
		$Title_Screen/Username.select_all()
		$Title_Screen/Username.grab_focus()
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
			User.client.send_user_name($Title_Screen/Username.text)
			User.player_color = bot_color
	
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

	
func _on_quit_pressed():
	get_tree().quit(0)

func invalid_name():
	var new_main_menu = main_menu_template.instantiate()
	get_parent().add_child(new_main_menu)
	var pop_up = pop_up_template.instantiate()
	pop_up.set_msg("Invalid name!")
	new_main_menu.add_child(pop_up)
	queue_free()


func _on_multiplayer_pressed():
	$Title_Screen/Username.set_visible(true)
	await get_tree().create_timer(0.1).timeout
	$Title_Screen/Title_Screen_box/Multiplayer10.set_visible(false)
	$Title_Screen/Enter.set_visible(true)

func _on_color_changer_pressed() -> void:
	$Background/AnimatedBot/AnimationTree.get("parameters/playback").travel("fall_end")
	bot_color += 1
	if bot_color > 8:
		bot_color = 1
	$Background/AnimatedBot.set_color(bot_color)
	User.player_color = bot_color

func _on_singleplayer_pressed():
	var peer = OfflineMultiplayerPeer.new()
	User.ID = peer.get_unique_id()
	if User.client:
		User.client.queue_free()
	User.client = Client.new()
	User.client.ws.close()
	get_parent().add_child(User.client)
		
	User.current_lobby_seed = RandomNumberGenerator.new().randi()
	var game_scene = game_scene_template.instantiate()
	game_scene.set_multiplayer_authority(User.ID)
	game_scene.name = "game_scene"
	get_parent().get_parent().add_child(game_scene)

	var player_character = player_character_template.instantiate()
	player_character.set_multiplayer_authority(User.ID)
	player_character.global_position = Vector2(0, -6)
	player_character.get_node("Control/VBoxContainer/Control2").visible = false
	player_character.get_node("Control/VBoxContainer/Control/TextureProgressBar").position = Vector2(0, 19)
	player_character.get_node("Label").position = Vector2(-19, -68)

	get_node("../../game_scene").add_child(player_character)

	player_character.set_sprite(bot_color)
	queue_free()


func _on_leaderboard_pressed():
	var peer = OfflineMultiplayerPeer.new()
	User.ID = peer.get_unique_id()
	if User.client:
		User.client.queue_free()
	User.client = Client.new()
	User.client.ws.close()
	get_parent().add_child(User.client)
		
	var tutorial_scene = tutorial_template.instantiate()
	get_parent().get_parent().add_child(tutorial_scene)

	var tutorial_player_character = tutorial_player_template.instantiate()
	tutorial_player_character.set_multiplayer_authority(User.ID)
	tutorial_player_character.global_position = Vector2(-520, -90)

	get_node("../../tutorial").add_child(tutorial_player_character)
	
	tutorial_player_character.set_sprite(bot_color)
	queue_free()

func _on_enter_pressed():
	_on_username_text_submitted($Title_Screen/Username.text)
	pass # Replace with function body.
