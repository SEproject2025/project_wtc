extends Node

const POP_UP_START_POSITION_X = -625
const POP_UP_START_POSITION_Y = -400

var pop_up_template = preload("res://scenes/pop_up.tscn")
var start_time : float = 5.0
var pop_up

func _ready():
	User.client.some_one_left_game.connect(player_left)
	pop_up = pop_up_template.instantiate()
	pop_up.name = "pop_up"
	pop_up.set_msg("5")
	pop_up.is_button_visible(false)
	pop_up.set_background_color(Color(0, 0, 0, 0))
	pop_up.position.x = POP_UP_START_POSITION_X
	pop_up.position.y = POP_UP_START_POSITION_Y
	pop_up.z_index = 10
	add_child(pop_up)
	if User.is_host:
		User.client.send_map_seed(RandomNumberGenerator.new().randi())


func _process(delta):
	var second_left : float = start_time - delta
	start_time -= delta
	pop_up.set_msg(str(floor(second_left)))
	
	if start_time <= 0:
		set_process(false)
		get_node("pop_up").queue_free()
		get_node("DeathWallNode").death_wall_start = true

func _on_button_pressed():
	User.reset_connection()
	
	for child in get_children():
		child.queue_free()

func player_left(other_player_id : int):
	User.rtc_peer.peer_disconnected.emit(other_player_id)