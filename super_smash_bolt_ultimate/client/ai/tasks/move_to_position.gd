extends BTAction

@export var target_position: StringName = &"pos"
@export var direction_var: StringName = &"dir"

@export var speed = 40
@export var tolerance = 10

func _tick(_delta: float) -> Status:
	if !User.is_host:
		return FAILURE
	var target_pos: Vector2 = blackboard.get_var(target_position, Vector2.ZERO)
	var direction = blackboard.get_var(direction_var)

	if abs(agent.global_position.x - target_pos.x) < tolerance:
		agent.move.rpc(direction, 0)
		return SUCCESS
	else:
		agent.move.rpc(direction, speed)
		return RUNNING
