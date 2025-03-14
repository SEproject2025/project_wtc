extends GridContainer

@onready var lobbyRank = $Rank
@onready var playerName = $Player
@onready var distance = $Distance


func set_player(player, rank) -> void:
	$Rank.text = str(rank)
	$Player.text = player.character_name.text
	$Distance.text = "%.2f" % player.maxDisplacement + "m"
