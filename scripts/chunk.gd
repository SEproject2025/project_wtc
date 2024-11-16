extends Node2D

@onready var level = $"../"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta):
	if !MultiplayerManager.multiplayer_mode_enabled and !multiplayer.is_server():
		singleplayer_algorithm()
	else:
		multiplayer_algorithm()

func singleplayer_algorithm():
	var player = get_parent().get_parent().get_node("Player")
	if global_position.distance_to(player.global_position) > 1000 and player.global_position.x > global_position.x:
			level.singleplayer_algorithm(position.x+(level.amnt*level.offset))
			queue_free()

func multiplayer_algorithm():
	var playersNode = get_tree().get_current_scene().get_node("Players").get_children()

	for playerNode in playersNode:
		if global_position.distance_to(playerNode.global_position) > 1000 and playerNode.global_position.x > global_position.x:
			level.multiplayer_algorithm(position.x+(level.amnt*level.offset))
			queue_free()
			break
