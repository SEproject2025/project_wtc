extends CanvasLayer
var current_player_index = 0
var other_players = []
@onready var previousButton = $Previous
@onready var nextButton = $Next

func _ready() -> void:
	User.client.connect("player_died", update_dead_players)
	if other_players.size() <= 1:
		previousButton.visible = false
		nextButton.visible = false

func set_msg(_msg: String):
	$Container/CharacterName.text = _msg

func _next_player():
	deactivate_current_camera(current_player_index)
	current_player_index = (current_player_index + 1) % other_players.size()
	spectate_player(current_player_index)

func _previous_player():
	deactivate_current_camera(current_player_index)
	current_player_index = (current_player_index - 1 + other_players.size()) % other_players.size()
	spectate_player(current_player_index)

func spectate_player(index: int):
	if other_players.size() == 0:
		return
	var player = other_players[index]
	player.get_node("Camera2D").enabled = true
	set_msg(player.character_name.text)

func deactivate_current_camera(index: int):
	other_players[index].get_node("Camera2D").enabled = false

func update_dead_players(id: int):
	if other_players[current_player_index].name == str(id):
		deactivate_current_camera(current_player_index)
	other_players = other_players.filter(func(player): return player.name != str(id))
	if other_players.size() <= 1:
		previousButton.visible = false
		nextButton.visible = false
	if current_player_index >= other_players.size():
		current_player_index = 0
	spectate_player(current_player_index)