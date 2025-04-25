extends Node2D


@onready var level = $"../"
@onready var parallax_background = $"../../CaveBackground"
@onready var Forestsound = $"../../ForestAmbience"
@onready var Cavesound = $"../../CaveAmbience"
var gave_birth = false
var player_in_cave = true
var biome_switch_distance = 400
# func _ready() -> void:
# 	User.client.some_one_left_game.connect(get_players)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta):
	var players = get_tree().get_nodes_in_group("Players")
				
	var first_place = 0
	var last_place  = 100000
	for player in players:
		if player.alive:
			if global_position.x - player.global_position.x < biome_switch_distance and player_in_cave: #.distance_to(player.global_position) < 500 and player.global_position.x < global_position.x and player_in_cave:
				parallax_background.cavetoforest()
				Cavesound.fading = true
				Forestsound.play_sound = true
				player_in_cave = false
				print("animation instantiated!")
			if (player.position.x < last_place):
					last_place = player.position.x
			if(player.position.x > first_place):
				first_place = player.position.x
			if global_position.x - first_place <= (level.offset*2) and first_place < global_position.x and !gave_birth:
			
				level.algorithm(position.x+(level.offset))
			gave_birth = true
			if  last_place - global_position.x >= (level.offset*2) and last_place > global_position.x  and gave_birth:
				queue_free()
