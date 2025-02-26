extends BTAction

func _tick(_delta: float) -> Status:
	# if !User.is_host or !agent.alive:
	# 	return FAILURE
	agent.play_animation("warning")
	return SUCCESS
