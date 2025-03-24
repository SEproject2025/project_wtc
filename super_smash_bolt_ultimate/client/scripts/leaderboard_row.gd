extends GridContainer

@onready var playerName = $Player.text
@onready var distance = $Distance.text
@onready var animPlayer = $AnimationPlayer

var playerID: String = ""
var playerDistance: float = 0.0


func set_player(player, rank=0) -> void:
	$Rank.text = str(rank)
	$Player.text = player.character_name.text
	$Distance.text = "%.2f" % player.maxDisplacement + "m"
	playerID = str(player.name)
	playerDistance = player.maxDisplacement

func update_distance(displacement: float) -> void:
	$Distance.text = "%.2f" % displacement + "m"
	playerDistance = displacement

func update_rank(new_rank: String) -> void:
	$Rank.text = new_rank

func move_up_anim() -> void:
	var start_position = position.y
	animPlayer.stop()
	animPlayer.clear_caches()
	animPlayer.get_animation("move_up").track_set_key_value(0, 0, position.y)
	animPlayer.get_animation("move_up").track_set_key_value(0, 1, start_position - 47)
	animPlayer.play("move_up")

func move_down_anim() -> void:
	var start_position = position.y
	animPlayer.stop()
	animPlayer.clear_caches()
	animPlayer.get_animation("move_down").track_set_key_value(0, 0, position.y)
	animPlayer.get_animation("move_down").track_set_key_value(0, 1, position.y + 47)
	animPlayer.play("move_down")
	await animPlayer.animation_finished
