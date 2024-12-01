extends CanvasLayer

var pop_up_template = preload("res://scenes/pop_up.tscn")
var lobby_menu_template = preload("res://scenes/lobby_menu.tscn")

func _on_play_again_pressed():
	pass
	# var pop_up = pop_up_template.instantiate()
	# pop_up.set_msg("   returning to the lobby menu...")
	# pop_up.is_button_visible(false)
	# add_child(pop_up)
	# User.is_host = false
	# User.host_name = ""
	# User.peers.clear()
	# User.connection_list.clear()
	# User.client.send_left_info(User.current_lobby_name)
	# await get_tree().create_timer(1).timeout
	# User.client.request_lobby_list()
	# get_parent().add_child(lobby_menu_template.instantiate())
	# pop_up.queue_free()
	# queue_free()