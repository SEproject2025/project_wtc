extends Node2D

@onready var level = $"../"



# func _ready() -> void:
# 	User.client.some_one_left_game.connect(get_players)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta):
	# if !players:
	# 	get_players()
	var players = get_tree().get_nodes_in_group("Players")
	for player in players:
		if global_position.distance_to(player.global_position) > 1000 and player.global_position.x > global_position.x:
			level.algorithm(position.x+(level.amnt*level.offset))
			queue_free()

# func get_players():
# 	players = get_tree().get_nodes_in_group("Players")
