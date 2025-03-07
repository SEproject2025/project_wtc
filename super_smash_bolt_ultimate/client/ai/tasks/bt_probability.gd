@tool
extends BTDecorator

@export var probability: float = 0.5
var received_seed: bool = false;
var rng := RandomNumberGenerator.new()

# Display a customized name (requires @tool).
func _generate_name() -> String:
	return "Custom BT Probability"


# Called once during initialization.
func _setup() -> void:
	if User.is_host:
		User.client.request_seed()
	User.client.generated_seed_received.connect(on_generated_seed_received)


# Called each time this task is ticked (aka executed).
func _tick(delta: float) -> Status:
	if not received_seed:
		return FAILURE
		
	if(rng.randf() <= probability or get_child(0).get_status() == RUNNING):
		return get_child(0).execute(delta)
		
	return FAILURE
		


func on_generated_seed_received(generated_seed: int):
	print(generated_seed)
	rng.seed = generated_seed
	received_seed = true