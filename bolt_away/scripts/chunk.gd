extends Node2D

@onready var level = $"../"

var player
var playersNode

func _ready() -> void:
	MultiplayerManager.connect("client_joined", get_player_node)
	if !MultiplayerManager.multiplayer_mode_enabled:
		player = get_tree().get_current_scene().get_node("Player")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta):
	if !MultiplayerManager.multiplayer_mode_enabled:
		singleplayer_algorithm()
	else:
		multiplayer_algorithm()

func singleplayer_algorithm():
	if global_position.distance_to(player.global_position) > 1000 and player.global_position.x > global_position.x:
			level.singleplayer_algorithm(position.x+(level.amnt*level.offset))
			queue_free()

func multiplayer_algorithm():
	if !playersNode:
		get_player_node()

	for playerNode in playersNode:
			if global_position.distance_to(playerNode.global_position) > 1000 and playerNode.global_position.x > global_position.x:
				level.multiplayer_algorithm(position.x+(level.amnt*level.offset))
				queue_free()
				break

func get_player_node():
	playersNode = get_tree().get_current_scene().get_node("Players").get_children()
