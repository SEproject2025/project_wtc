extends BTAction

@export var group: StringName
@export var target_var: StringName = &"target"

var target

func _tick(_delta: float) -> Status:
	if group == "Players":
		target = get_player_node()
	blackboard.set_var(target_var, target)
	return SUCCESS

func get_player_node():
	var nodes: Array[Node] = agent.get_tree().get_nodes_in_group(group)
	if nodes.is_empty():
		return null
	var closest_node = nodes[0]
	var closes_distance = agent.global_position.distance_to(closest_node.global_position)
	for node in nodes:
		var distance = agent.global_position.distance_to(node.global_position)
		if distance < closes_distance:
			closest_node = node
			closes_distance = distance
	return closest_node
