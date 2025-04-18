extends Node

const POP_UP_START_POSITION_X = -625
const POP_UP_START_POSITION_Y = -400


var pop_up_template = preload("res://scenes/pop_up.tscn")
var start_time : float = 5.0
var pop_up

@onready var end_pop_up = $EndPopUp
@onready var end_vbox = $EndPopUp/MarginContainer/VBoxContainer

func _ready():
	User.client.some_one_left_game.connect(player_left)
	User.client.other_user_joined_lobby.connect(_other_user_joined_game)
	if !User.is_spectator:
		pop_up = pop_up_template.instantiate()
		pop_up.name = "pop_up"
		pop_up.set_msg("5")
		pop_up.is_button_visible(false)
		pop_up.set_background_color(Color(0, 0, 0, 0))
		pop_up.position.x = POP_UP_START_POSITION_X
		pop_up.position.y = POP_UP_START_POSITION_Y
		pop_up.z_index = 10
		add_child(pop_up)
	else:
		set_process(false)
	
	end_vbox.get_node("Message").visible = false
	end_vbox.get_node("BoxContainer").visible = false
	end_vbox.get_node("LeaderboardContainer").visible = false
	
	#if User.is_host:
		#User.client.send_map_seed(RandomNumberGenerator.new().randi())
	


func _process(delta):
	var second_left : float = start_time - delta
	start_time -= delta
	pop_up.set_msg(str(floor(second_left)))
	
	if start_time <= 0:
		set_process(false)
		get_node("pop_up").queue_free()
		get_node("DeathWallNode").death_wall_start = true
		end_pop_up.setup()

func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_TAB:
			if (is_instance_valid(end_pop_up) and end_pop_up.leaderboard_enabled):
				end_pop_up.leaderboard_container.visible = !end_pop_up.leaderboard_container.visible
				if end_pop_up.leaderboard_container.allPlayers.size() == 0 or end_pop_up.leaderboard_container.names_not_set():
					end_pop_up.leaderboard_container.setup()

func _on_button_pressed():
	User.reset_connection()
	
	for child in get_children():
		child.queue_free()

func player_left(other_player_id : int):
	User.rtc_peer.peer_disconnected.emit(other_player_id)
	# get_node(str(other_player_id)).queue_free()

func enable_death_pop_up() -> void:
	end_pop_up._ready()
	end_vbox.get_node("Message").visible = true
	end_vbox.get_node("BoxContainer").visible = true

func _other_user_joined_game(_username: String):
	for peer_id in User.peers.keys():
		if !User.connection_list.has(peer_id):
			User.connect_to_peer(peer_id)
