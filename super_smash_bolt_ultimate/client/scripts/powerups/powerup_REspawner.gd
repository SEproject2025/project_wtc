extends Area2D


@export var powerups:Array[Constants.PowerUpType]
@export var powerupProbabilities: Array[float]

@onready var respawn_timer = $Respawn_Timer

func _ready() -> void:
	var sum = 0.0
	for i in range(powerups.size()):
		sum += powerupProbabilities[i]
	assert(sum == 1.0)

func _on_body_entered(body):
	if body.is_in_group("Players") and $Sprite2D.visible:
		body.powerupManager.collect_powerup(get_random_powerup())
		respawn_timer.start()
		$Sprite2D2.visible = false
		$Sprite2D.visible = false
		#queue_free()

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


func _on_respawn_timer_timeout() -> void:
	$Sprite2D.visible = true
	$Sprite2D2.visible = true
