extends Control

@onready var leaderboardList = $TabContainer/Leaderboard/MarginContainer/VBoxContainer/List

var leaderboardRowTemplate = preload("res://scenes/leaderboard_row.tscn")


func set_leaderboard(allPlayers: Array) -> void:
	var rank: int = 1
	allPlayers.sort_custom(func(a, b): return a.maxDisplacement > b.maxDisplacement)
	for player in allPlayers:
		var leaderboardRow = leaderboardRowTemplate.instantiate()
		leaderboardRow.set_player(player, rank)
		$TabContainer/Leaderboard/MarginContainer/VBoxContainer/List.add_child(leaderboardRow)
		rank += 1
