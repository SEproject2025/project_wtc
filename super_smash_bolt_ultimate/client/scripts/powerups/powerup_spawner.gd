extends Area2D


@export var powerups:Array[Constants.PowerUpType]
@export var powerupProbabilities: Array[float]

func _ready() -> void:
	var sum = 0.0
	for i in range(powerups.size()):
		sum += powerupProbabilities[i]
	assert(sum == 1.0)

func _on_body_entered(body):
	if body.is_in_group("Players"):
		body.powerupManager.collect_powerup(get_random_powerup())
		queue_free()

func get_random_powerup():
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var random_weight = rng.randf_range(0.0, 1.0)
	
	var current_weight = 0.0
	for i in range(powerupProbabilities.size()):
		current_weight += powerupProbabilities[i]
		if random_weight <= current_weight:
			return powerups[i]
	
	return Constants.PowerUpType.NONE
