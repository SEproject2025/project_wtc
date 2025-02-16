extends BTAction

@export var group: StringName
@export var target_var: StringName = &"target"

var target

func _tick(_delta: float) -> Status:
    if !User.is_host:
        return FAILURE
    if group == "Players":
        target = get_player_node()
    blackboard.set_var(target_var, target)
    return SUCCESS

func get_player_node():
    var nodes: Array[Node] = agent.get_tree().get_nodes_in_group(group)
    return nodes[0]