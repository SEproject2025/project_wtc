extends CanvasLayer

var pop_up_template = preload("res://scenes/pop_up.tscn")
func _on_continue_pressed():
	queue_free()

func _on_quit_pressed():
	var pop_up = pop_up_template.instantiate()
	pop_up.set_msg("   returning to the lobby menu...")
	pop_up.is_button_visible(false)
	add_child(pop_up)
	User.is_host = false
	User.host_name = ""
	User.peers.clear()
	User.connection_list.clear()
	User.client.send_left_game(User.current_lobby_name)
	await get_tree().create_timer(1).timeout
	User.client.request_lobby_list()
	get_tree().get_root().add_child(load("res://scenes/lobby_menu.tscn").instantiate())
	pop_up.queue_free()
	var game_scene_node = get_tree().get_root().get_node("game_scene")
	game_scene_node.get_node(str(User.ID)).queue_free()
	game_scene_node.queue_free()
	queue_free()
