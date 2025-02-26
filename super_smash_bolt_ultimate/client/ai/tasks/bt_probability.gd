@tool
extends BTDecorator

@export var probability: float = 0.5
var rng := RandomNumberGenerator.new()

# Display a customized name (requires @tool).
func _generate_name() -> String:
	return "Custom BT Probability"


# Called once during initialization.
func _setup() -> void:
	rng.seed = User.client.ai_seed;


# Called each time this task is ticked (aka executed).
func _tick(delta: float) -> Status:
	if(rng.randf() <= probability or get_child(0).get_status() == RUNNING):
		return get_child(0).execute(delta)
		
	return FAILURE
		


