extends Node2D


@onready var level = $"../"
@onready var parallax_background = $"../../CaveBackground"
@onready var Forestsound = $"../../ForestAmbience"
@onready var Cavesound = $"../../CaveAmbience"

var anim_count = 0
var played = false
# func _ready() -> void:
# 	User.client.some_one_left_game.connect(get_players)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta):
	# if !players:
	# 	get_players()
	var players = get_tree().get_nodes_in_group("Players")
	for player in players:
		if (global_position.distance_to(player.global_position) < 500 and player.global_position.x < global_position.x and anim_count != 1)\
			or (level.count >= 5 and level.count < 10 and not played):
			parallax_background.cavetoforest()
			Cavesound.fading = true
			Forestsound.play_sound = true
			
			anim_count += 1
			played = true
		if global_position.distance_to(player.global_position) > 1000 and player.global_position.x > global_position.x:
			level.algorithm(position.x+(level.amnt*level.offset))
			queue_free()
