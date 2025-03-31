

extends Node2D

const NUMBER_OF_TRAILING_CHUNKS = 3
const NUMBER_OF_TRAILING_HALF_CHUNKS = NUMBER_OF_TRAILING_CHUNKS * 2

@onready var level = $"../"
@onready var parallax_background = $"../../CaveBackground"
@onready var Forestsound = $"../../ForestAmbience"
@onready var Cavesound = $"../../CaveAmbience"

var gave_birth = false
var player_in_cave = true

func _physics_process(_delta):
	var players = get_tree().get_nodes_in_group("Players")
	for player in players:
		if player.global_position.x > global_position.x - (0.5*level.offset) and player.is_in_cave: #.distance_to(player.global_position) < 500 and player.global_position.x < global_position.x and player_in_cave:
			player.set_background("forest")
			Cavesound.fading = true
			Forestsound.play_sound = true
			player.is_in_cave = false
			print("animation instantiated!")
			
		elif player.global_position.x < global_position.x - (0.5*level.offset) and !player.is_in_cave:
			player.set_background("cave")
			Forestsound.fading = true
			Cavesound.play_sound = true
			player.is_in_cave = true
			print("reverse animation instantiated!")
			
		
			
		if global_position.distance_to(player.global_position) > 1000 and player.global_position.x > global_position.x:
			level.algorithm(position.x+(level.amnt*level.offset))
			queue_free()

#func _physics_process(_delta):
	#var players = get_tree().get_nodes_in_group("Players")
	#var first_place = players[0].global_position.x
	#var last_place = players[0].global_position.x
	#for player in players:
		#if player.global_position.x > first_place:
			#first_place = player.global_position.x
		#if player.global_position.x < last_place:
			#last_place = player.global_position.x
#
	#if !gave_birth and first_place > global_position.x:
		#if player_in_forrest:
			#parallax_background.cavetoforest()
			#Cavesound.fading = true
			#Forestsound.play_sound = true
			#player_in_forrest = false
		#if !gave_birth:
			#level.algorithm(position.x+(level.amnt*level.offset))
			#gave_birth = true
	#if last_place > global_position.x + level.amnt*level.offset:
		#print("Removing This Chunk...")
		#queue_free()
