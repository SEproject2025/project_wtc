extends CanvasLayer

var pop_up_template = preload("res://scenes/pop_up.tscn")
var in_lobby_menu_template = preload("res://scenes/in_lobby_menu.tscn")
var player_character_template = preload("res://scenes/player_character.tscn")


func _ready():
	if User.ID == MultiplayerPeer.TARGET_PEER_SERVER:
		$VBoxContainer/RestartContainer.visible = true
		self.process_mode = Node.PROCESS_MODE_ALWAYS
		$VBoxContainer/ContinueContainer/ContinueButton.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
		$VBoxContainer/RestartContainer/RestartButton.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
		$VBoxContainer/QuitContainer/QuitButton.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
		

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			_on_pause_pressed()

func _on_continue_pressed():
	if User.ID == MultiplayerPeer.TARGET_PEER_SERVER:
		get_tree().paused = false
	$Pause.visible = true
	$ColorRect.visible = false
	$VBoxContainer.visible = false

func _on_restart_pressed():
	self.reparent(get_tree().get_root())
	get_tree().get_root().get_node("game_scene").free()
	User.current_lobby_seed = RandomNumberGenerator.new().randi()
	var game_scene = load("res://scenes/game_scene.tscn").instantiate()
	game_scene.set_multiplayer_authority(User.ID)
	game_scene.name = "game_scene"
	get_tree().get_root().add_child(game_scene)

	var player_character = player_character_template.instantiate()
	player_character.set_multiplayer_authority(User.ID)
	player_character.global_position = Vector2(0, -6)
	player_character.get_node("Control/VBoxContainer/Control2").visible = false
	get_tree().get_root().get_node("game_scene").add_child(player_character)

	get_tree().paused = false
	queue_free()

func _on_quit_pressed():
	var game_scene_node = get_tree().get_root().get_node("game_scene")
	var main_node = get_tree().get_root().get_node("main")
	if User.ID == MultiplayerPeer.TARGET_PEER_SERVER:
		self.reparent(get_tree().get_root())
		game_scene_node.queue_free()
		var main_menu = load("res://scenes/main_menu.tscn").instantiate()
		main_node.add_child(main_menu)
		get_tree().paused = false
	else:
		var pop_up = pop_up_template.instantiate()
		pop_up.set_msg("   returning to lobby...")
		pop_up.is_button_visible(false)
		add_child(pop_up)

		if get_tree().get_nodes_in_group("Players").size() <= 1:
			User.client.restart_lobby(User.current_lobby_name)
			await get_tree().create_timer(.2).timeout

		User.client.send_left_game(User.current_lobby_name)
		await get_tree().create_timer(.2).timeout
		pop_up.queue_free()
		var in_lobby_menu = in_lobby_menu_template.instantiate()
		main_node.add_child(in_lobby_menu)
		User.client.request_join_lobby(User.current_lobby_name)
		game_scene_node.queue_free()
	queue_free()


func _on_pause_pressed() -> void:
	if User.ID == MultiplayerPeer.TARGET_PEER_SERVER:
		get_tree().paused = !get_tree().paused
	$Pause.visible = !$Pause.visible
	$ColorRect.visible = !$ColorRect.visible
	$VBoxContainer.visible = !$VBoxContainer.visible
	$VBoxContainer/ContinueContainer/ContinueButton.grab_focus()
