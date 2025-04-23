extends Node2D

@onready var level = $"../"

var gave_birth = false

# func _ready() -> void:
# 	User.client.some_one_left_game.connect(get_players)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta):
	var players = get_tree().get_nodes_in_group("Players")
	var first_place = 0
	var last_place  = 100000
	for player in players:
		if player.alive:
			if (player.position.x < last_place):
					last_place = player.position.x
			if(player.position.x > first_place):
				first_place = player.position.x
			if global_position.x - first_place <= (level.offset*2) and first_place < global_position.x and !gave_birth:
				
				level.algorithm(position.x+(level.offset))
				gave_birth = true
			if  last_place - global_position.x >= (level.offset*2) and last_place > global_position.x  and gave_birth:
				queue_free()

# func get_players():
# 	players = get_tree().get_nodes_in_group("Players")
