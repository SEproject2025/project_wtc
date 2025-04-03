extends Node2D
@onready var level = $"../"
@onready var parallax_background = $"../../CaveBackground"
@onready var Forestsound = $"../../ForestAmbience"
@onready var Cavesound = $"../../CaveAmbience"

var gave_birth = false
var anim_count = 0
# func _ready() -> void:
# 	User.client.some_one_left_game.connect(get_players)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta):
	# if !players:
	# 	get_players()
	var players = get_tree().get_nodes_in_group("Players")
	var first_place = 0
	var last_place  = 100000
	for player in players:
		if global_position.distance_to(player.global_position) > 400 and player.global_position.x > global_position.x and anim_count < 1:
			player.set_background("cave")
			Forestsound.fading = true
			Cavesound.play_sound = true
			anim_count += 1
		if player.alive:
			if (player.position.x < last_place):
					last_place = player.position.x
			if(player.position.x > first_place):
				first_place = player.position.x
	if global_position.x - first_place <= 1000 and first_place < global_position.x and !gave_birth:
		
		level.algorithm(position.x+(level.offset))
		gave_birth = true
	if  last_place - global_position.x >= 1000 and last_place > global_position.x  and gave_birth:
		queue_free()
