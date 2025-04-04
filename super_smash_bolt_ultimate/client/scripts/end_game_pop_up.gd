extends CanvasLayer

@onready var spectate_button = $MarginContainer/VBoxContainer/BoxContainer/Spectate
@onready var box_container = $MarginContainer/VBoxContainer/BoxContainer
@onready var leaderboard_container = $MarginContainer/VBoxContainer/LeaderboardContainer

var pop_up_template = preload("res://scenes/pop_up.tscn")
var spectator_overlay = preload("res://scenes/spectator_overlay.tscn")
var in_lobby_menu_template= preload("res://scenes/in_lobby_menu.tscn")
var leaderboard_enabled = true


var other_players = []
var all_players = []

var spectator_overlay_instance
var is_spectating = false

func _ready() -> void:
	setup()
	User.client.connect("player_died", player_died)

func setup() -> void:
	all_players = get_tree().get_nodes_in_group("Players")
	other_players = all_players.filter(func(player): return player.name != str(User.ID) && player.alive)	
	spectate_button.visible = other_players.size() > 0
	leaderboard_enabled = all_players.size() > 1

func player_died(_player_name: int) -> void:
	if !is_spectating:
		setup()


func _on_play_again_pressed():
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


func _on_spectate_pressed() -> void:
	if !other_players:
		setup()
	is_spectating = true
	spectator_overlay_instance = spectator_overlay.instantiate()
	spectator_overlay_instance.other_players = other_players
	spectator_overlay_instance.spectate_player(0)

	get_tree().get_root().get_node("game_scene").add_child(spectator_overlay_instance)
	
	for child in $MarginContainer/VBoxContainer.get_children():
		if child != leaderboard_container:
			child.queue_free()
