extends Area2D


func on_entered(body):
	if body.name == "Player" || body is MultiplayerPlayer:
		body.oil_slip()