extends Control

@onready var leaderboardList = $TabContainer/Leaderboard/MarginContainer/VBoxContainer/List

var leaderboardRowTemplate = preload("res://scenes/leaderboard_row.tscn")
var allPlayers = []

func _ready() -> void:
	setup()
	
func setup():
	allPlayers = get_tree().get_nodes_in_group("Players")
	for player in allPlayers:
		player.displacement_updated.connect(update_leaderboard)
	set_leaderboard(allPlayers)

func set_leaderboard(allPlayers: Array) -> void:
	var rank: int = 1
	allPlayers.sort_custom(func(a, b): return a.maxDisplacement > b.maxDisplacement)

	var listContainer = $TabContainer/Leaderboard/MarginContainer/VBoxContainer/List
	for child in listContainer.get_children():
		child.queue_free()

	for player in allPlayers:
		var leaderboardRow = leaderboardRowTemplate.instantiate()
		leaderboardRow.set_player(player, rank)
		listContainer.add_child(leaderboardRow)
		listContainer.add_child(HSeparator.new())
		rank += 1

func update_leaderboard(player_name: String, maxDisplacement: float) -> void:
	var children = leaderboardList.get_children()
	var rows = children.filter(func(row): return row is not HSeparator)

	# Find the player's row
	var playerRow = rows.filter(func(row): return row.playerID == str(player_name)).front()

	# Update the player's distance
	playerRow.update_distance(maxDisplacement)
	var playerRowIndex = rows.find(playerRow)
	var previousPlayer = rows[playerRowIndex - 1]

	# Move the player up in the leaderboard if necessary
	while playerRowIndex > 0 and previousPlayer.playerDistance < playerRow.playerDistance:
	
		
		# Get the separator node between them
		var playerNodeIndex = playerRow.get_index()
		var separatorNode = children[playerNodeIndex + 1] if playerNodeIndex + 1 < children.size() else null

		var temp_rank = previousPlayer.get_node("Rank").text
		previousPlayer.update_rank(playerRow.get_node("Rank").text)
		playerRow.update_rank(temp_rank)
		
		# previousPlayer.tween_anim(playerNodeIndex)
		leaderboardList.move_child(playerRow, playerNodeIndex - 2)
		if separatorNode:
			leaderboardList.move_child(separatorNode, playerNodeIndex - 1)
		


		children = leaderboardList.get_children()
		rows = children.filter(func(row): return row is not HSeparator)
		playerRowIndex = rows.find(playerRow)
		previousPlayer = rows[playerRowIndex - 1]


func names_not_set() -> bool:
	var rows = leaderboardList.get_children().filter(func(row): return row is not HSeparator)
	return rows.any(func(row): return row.playerName == "Player name" or row.playerName == "Other player")	