extends BTAction

func _tick(_delta: float) -> Status:
	if !User.is_host:
		return FAILURE
	agent.play_animation.rpc("warning")
	return SUCCESS
