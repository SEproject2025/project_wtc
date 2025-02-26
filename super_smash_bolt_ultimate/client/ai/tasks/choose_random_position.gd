extends BTAction

@export var range_min_in_direction: float = 10.0
@export var range_max_in_direction: float = 50.0

@export var position_var: StringName = &"pos"
@export var direction_var: StringName = &"dir"
var rng := RandomNumberGenerator.new()

func _setup() -> void: 
	rng.seed = User.client.ai_seed;

func _tick(_delta: float) -> Status:
	var pos: Vector2
	var direction = random_direction()

	pos = random_position(direction)
	blackboard.set_var(position_var, pos)

	return SUCCESS

func random_position(dir: int):
	var vector: Vector2
	var distance = rng.randi_range(range_min_in_direction, range_max_in_direction) * dir
	vector.x = distance + agent.global_position.x
	return vector


func random_direction():
	var dir = rng.randi_range(-2, 1)
	dir = -1 if abs(dir) != dir else 1
	blackboard.set_var(direction_var, dir)
	return dir
