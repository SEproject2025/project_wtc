extends Node2D

@export var chunks: Array[PackedScene]
@export var testChunks: Array[PackedScene]
var startingChunk: PackedScene = preload("res://chunks/starting_chunk.tscn")
var deathWall: PackedScene = preload("res://scenes/death_wall.tscn")

var amnt = 3
var offset = 512 
var start_offset = -200
var rng = RandomNumberGenerator.new()

func _ready() -> void:
	User.client.map_seed_received.connect(set_map_seed)
	spawn_starting_chunks()

func algorithm(n):
	var chunksToUse = testChunks if OS.is_debug_build() else chunks
	var num = rng.randi_range(0, chunksToUse.size()-1)
	add_chunk(num, n)

func spawn_starting_chunks():
	for n in amnt:
		var instance = startingChunk.instantiate()
		instance.position.x = n*offset + start_offset
		add_child(instance)

func add_chunk(num, chunkPosition):
	var instance
	if OS.is_debug_build():
		instance = testChunks[num].instantiate()
	else:
		instance = chunks[num].instantiate()
	instance.position.x = chunkPosition
	add_child(instance)

func set_map_seed(map_seed: int):	
	rng.seed = map_seed
