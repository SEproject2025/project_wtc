extends Node2D

@onready var level = $"../"
@onready var player = get_parent().get_parent().get_node("Player")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if global_position.distance_to(player.global_position) > 300 and player.global_position.x > global_position.x:
		level.spawnChunk(position.x+(level.amnt*level.offset))
		queue_free()
