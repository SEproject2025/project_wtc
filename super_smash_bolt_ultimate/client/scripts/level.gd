extends Node2D

@export var chunks: Array[PackedScene] = []
@export var forestchunks: Array[PackedScene] = []
@export var labchunks: Array[PackedScene] = []
var startingChunk: PackedScene = preload("res://chunks/starting_chunk.tscn")
var deathWall: PackedScene = preload("res://scenes/death_wall.tscn")

var amnt = 3
var count = 1
var offset = 512 
var start_offset = -200
var rng = RandomNumberGenerator.new()

func _ready() -> void:
	User.client.map_seed_received.connect(set_map_seed)
	spawn_starting_chunks()

func algorithm(n):
	if (count < 25):
		var num = rng.randi_range(0, chunks.size()-1)
		add_chunk(num, n)
	elif (count < 50):
		var num = rng.randi_range(0, forestchunks.size()-1)
		add_chunk(num, n)
	elif (count < 75):
		var num = rng.randi_range(0, labchunks.size()-1)
		add_chunk(num, n)
	else:
		count = 0

func spawn_starting_chunks():
	for n in amnt:
		var instance = startingChunk.instantiate()
		instance.position.x = n*offset + start_offset
		add_child(instance)

func add_chunk(num, chunkPosition):
	
	if (count < 25):
		var instance = chunks[num].instantiate()
		instance.position.x = chunkPosition
		add_child(instance)
	elif (count < 50):
		var instance = forestchunks[num].instantiate()
		instance.position.x = chunkPosition
		add_child(instance)
	elif (count < 75):
		var instance = labchunks[num].instantiate()
		instance.position.x = chunkPosition
		add_child(instance)
	count = count + 1
	print(count)

func set_map_seed(map_seed: int):	
	rng.seed = map_seed
