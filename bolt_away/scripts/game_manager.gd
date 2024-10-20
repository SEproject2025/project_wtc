extends Node

var score = 0

@onready var score_label = $ScoreLabel

func _ready():
	if OS.has_feature("dedicated_server"):
		print("hosting dedicated server")
		MultiplayerManager.host()

func add_point():
	score += 1
	score_label.text = "score: " + str(score)

func host():
	print("host")
	%MultiplayerHUD.hide()
	MultiplayerManager.host()
	
func join():
	print("join")
	%MultiplayerHUD.hide()
	MultiplayerManager.join()
