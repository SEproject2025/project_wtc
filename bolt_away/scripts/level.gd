extends Node2D

@export var chunks: Array[PackedScene] = []

var amnt = 3

var rng = RandomNumberGenerator.new()
var offset = 256
func _ready() -> void:
	for n in amnt:
		spawnChunk(n*offset)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func spawnChunk(n):
	
	rng.randomize()
	print("Chunk spawned")
	var num = rng.randi_range(0, chunks.size()-1)
	var instance = chunks[num].instantiate()
	instance.position.x = n
	add_child(instance)
	
