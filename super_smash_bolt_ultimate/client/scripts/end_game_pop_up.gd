extends CanvasLayer

var pop_up_template = preload("res://scenes/pop_up.tscn")
var spectator_overlay = preload("res://scenes/spectator_overlay.tscn")


func _on_play_again_pressed():
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
	get_parent().get_parent().get_parent().add_child(load("res://scenes/lobby_menu.tscn").instantiate())
	pop_up.queue_free()
	var game_scene_node = get_node("../../../game_scene")
	game_scene_node.queue_free()
	game_scene_node.get_node(str(User.ID)).queue_free()
	queue_free()


func _on_spectate_pressed() -> void:
	var other_players = get_tree().get_nodes_in_group("Players").filter(func(player): return player.name != str(User.ID))
	if other_players.size() == 0:
		var pop_up = pop_up_template.instantiate()
		pop_up.set_msg("No one to spectate!")
		add_child(pop_up)
		await get_tree().create_timer(1).timeout
		pop_up.queue_free()
		return
	var my_player = get_tree().get_root().get_node("game_scene").get_node(str(User.ID))
	my_player.get_node("Camera2D").enabled = false
	var spectatorOverlay = spectator_overlay.instantiate()
	spectatorOverlay.set_msg(other_players[0].character_name)
	add_child(spectatorOverlay)
	queue_free()
	


