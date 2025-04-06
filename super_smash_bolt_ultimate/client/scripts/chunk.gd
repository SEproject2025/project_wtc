extends Node2D

const NUMBER_OF_TRAILING_CHUNKS = 3
const NUMBER_OF_CHUNKS_AHEAD = 3
const NUMBER_OF_TRAILING_HALF_CHUNKS = NUMBER_OF_TRAILING_CHUNKS * 2

@onready var level = $"../"

var gave_birth = false

# func _ready() -> void:
# 	User.client.some_one_left_game.connect(get_players)

#func _physics_process(_delta):
	# if !players:
	# 	get_players()
	#var players = get_tree().get_nodes_in_group("Players")
	#var first_place = players[0].global_position.x
	#var last_place = players[0].global_position.x
	#for player in players:
	#	if player.global_position.x > first_place:
	#		first_place = player.global_position.x
	#	if player.global_position.x < last_place:
	#		last_place = player.global_position.x
#
	#	if first_place > global_position.x and !gave_birth:
	#		level.algorithm(position.x+(NUMBER_OF_CHUNKS_AHEAD*level.offset))
	#		gave_birth = true
#
		#if last_place > global_position.x + NUMBER_OF_TRAILING_CHUNKS*level.offset:
		#	print("Removing This Chunk...")
		#	queue_free()
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
	#for player in players:
		#if first_place > global_position.x and !gave_birth:
			#level.algorithm(position.x+(NUMBER_OF_CHUNKS_AHEAD*level.offset))
			#gave_birth = true
			#
		#if last_place > global_position.x + NUMBER_OF_TRAILING_CHUNKS*level.offset:
			#print("Removing This Chunk...")
			#queue_free()

		#if global_position.distance_to(player.global_position) > 1000 and player.global_position.x > global_position.x:
			#level.algorithm(position.x+(level.amnt*level.offset))
			#queue_free()

# func get_players():
# 	players = get_tree().get_nodes_in_group("Players")
