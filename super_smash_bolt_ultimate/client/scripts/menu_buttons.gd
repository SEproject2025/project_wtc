extends VBoxContainer

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


##Multiplayer button actions
func _on_multiplayer_button_entered():
	$MultiplayerHovered10.set_visible(true)
	$Multiplayer10.set_visible(false)
	pass # Replace with function body.


func _on_multiplayer_button_exited():
	$Multiplayer10.set_visible(true)
	$MultiplayerHovered10.set_visible(false)
	pass # Replace with function body.

##Singleplayer button actions
func _on_singleplayer_button_entered():
	$SingleplayerHovered10.set_visible(true)
	$Singleplayer10.set_visible(false)
	pass # Replace with function body.


func _on_singleplayer_button_exited():
	$Singleplayer10.set_visible(true)
	$SingleplayerHovered10.set_visible(false)
	pass # Replace with function body.

##Leaderboard button actions
func _on_leaderboard_button_entered():
	$LeaderboardHovered10.set_visible(true)
	$Leaderboard10.set_visible(false)
	pass # Replace with function body.


func _on_leaderboard_button_exited():
	$Leaderboard10.set_visible(true)
	$LeaderboardHovered10.set_visible(false)
	pass # Replace with function body.
