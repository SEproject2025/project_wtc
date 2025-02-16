extends BTAction

@export var target_var = &"target"

@export var speed = 120
@export var tolerance = 5


func _tick(_delta: float) -> Status:
	if !User.is_host:
		return FAILURE
	var target: CharacterBody2D = blackboard.get_var(target_var)
	if target == null:
		return FAILURE
	var target_position = target.global_position
	var direction = agent.global_position.direction_to(target_position)

	if abs(agent.global_position.x - target_position.x) < tolerance:
		agent.move.rpc(direction.x, 0)
		return SUCCESS
	else:
		agent.move.rpc(direction.x, speed)
		return RUNNING
