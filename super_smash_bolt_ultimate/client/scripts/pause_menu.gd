extends CanvasLayer

var pop_up_template = preload("res://scenes/pop_up.tscn")
var in_lobby_menu_template = preload("res://scenes/in_lobby_menu.tscn")

func _on_continue_pressed():
	visible = false

func _on_quit_pressed():
	var pop_up = pop_up_template.instantiate()
	pop_up.set_msg("   returning to lobby...")
	pop_up.is_button_visible(false)
	add_child(pop_up)
	
	if get_tree().get_nodes_in_group("Players").size() <= 1:
		User.client.restart_lobby(User.current_lobby_name)
		await get_tree().create_timer(.2).timeout
		
	User.is_spectator = false
	User.client.send_left_game(User.current_lobby_name)
	await get_tree().create_timer(.2).timeout
	pop_up.queue_free()
	var in_lobby_menu = in_lobby_menu_template.instantiate()
	in_lobby_menu.init_connection = false
	get_tree().get_root().get_node("main").add_child(in_lobby_menu)
	
	User.client.request_join_lobby(User.current_lobby_name)
	
	var game_scene_node = get_tree().get_root().get_node("game_scene")
	game_scene_node.queue_free()
	queue_free()
