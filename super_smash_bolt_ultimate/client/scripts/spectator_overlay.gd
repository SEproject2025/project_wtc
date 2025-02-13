extends CanvasLayer
var current_player_index = 0
var other_players = []
@onready var previousButton = $Previous
@onready var nextButton = $Next

func _ready() -> void:
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
	var player = other_players[index]
	player.get_node("Camera2D").enabled = true
	set_msg(player.character_name.text)

func deactivate_current_camera(index: int):
	var player = other_players[index]
	player.get_node("Camera2D").enabled = false