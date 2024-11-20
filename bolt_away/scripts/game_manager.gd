extends Node

var score = 0
var singlePlayerEnabled = false

@onready var score_label = $ScoreLabel
@onready var end_game_screen = get_parent().get_node("EndGameScreen")

func _ready():
	if OS.has_feature("dedicated_server"):
		print("hosting dedicated server")
		MultiplayerManager.host()
	end_game_screen.hide()

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

func exit():
	if MultiplayerManager.multiplayer_mode_enabled:
		if multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
			if !multiplayer.is_server() or !OS.has_feature("dedicated_server"):
				MultiplayerManager._disconnect_player(multiplayer.get_unique_id())
	get_tree().paused = false
	get_tree().reload_current_scene()
	Engine.time_scale = 1.0

func _on_single_player_pressed() -> void:
	%MultiplayerHUD.hide()
	singlePlayerEnabled = true
	var deathWall = get_tree().get_current_scene().get_node("DeathWallNode")
	deathWall.death_wall_start = true
	deathWall.position.x = -270 
	deathWall.wall_velocity = 25
	
