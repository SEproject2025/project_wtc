extends Node2D

@onready var level = $"../"
@onready var player = get_parent().get_parent().get_node("Player")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if !MultiplayerManager.multiplayer_mode_enabled:
		singleplayer_algoritm()
	else:
		multiplayer_algoritm()

func singleplayer_algoritm():
	if global_position.distance_to(player.global_position) > 300 and player.global_position.x > global_position.x:
			level.spawnChunk(position.x+(level.amnt*level.offset))
			queue_free()

func multiplayer_algoritm():
	var playersNode = get_tree().get_current_scene().get_node("Players").get_children()
	
	for multiplayer in playersNode:
		if global_position.distance_to(multiplayer.global_position) > 300 and multiplayer.global_position.x > global_position.x:
			level.spawnChunk(position.x+(level.amnt*level.offset))
			queue_free()
			break
