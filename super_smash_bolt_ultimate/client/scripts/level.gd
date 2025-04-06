extends Node2D

@export  var chunks:       Array[PackedScene] = []
@export  var forestchunks: Array[PackedScene] = []
@export  var labchunks:    Array[PackedScene] = []
@onready var parallax_background = $"../CaveBackground"
var startingChunk:  PackedScene = preload("res://chunks/starting_chunk.tscn")
var startingChunk2: PackedScene = preload("res://chunks/starting_chunk_2.tscn")
var cavetoforest:   PackedScene = preload("res://chunks/Cavetoforest.tscn")
var foresttocave:   PackedScene = preload("res://chunks/Foresttocave.tscn")
var deathWall:      PackedScene = preload("res://scenes/death_wall.tscn")

var amnt = 3
var chunks_per_biome = 5
var number_of_starting_chunks = 5
var count = 0
var offset = 512 #* 3
var start_offset = -200
var rng = RandomNumberGenerator.new()

func _ready() -> void:
	User.client.map_seed_received.connect(set_map_seed)
	

func algorithm(n):
	print("rng: ", rng.seed, "USER ID: ", str(User.ID))
	if (count < chunks_per_biome):
		var num = rng.randi_range(0, chunks.size()-1)
		add_chunk(num, n)
	elif (count == chunks_per_biome):
		var num = rng.randi_range(0, forestchunks.size()-1)
		add_chunk(num, n)
	elif (count < chunks_per_biome * 2):
		var num = rng.randi_range(0, forestchunks.size()-1)
		add_chunk(num, n)
	else:
		var num = rng.randi_range(0, forestchunks.size()-1)
		add_chunk(num, n)
		count = 0

func spawn_starting_chunks():
	for n in number_of_starting_chunks:
		if n != number_of_starting_chunks - 1:
			var instance = startingChunk.instantiate()
			instance.position.x = n*offset + start_offset
			add_child(instance)
		else:
			var instance = startingChunk2.instantiate()
			instance.position.x = n*offset + start_offset
			add_child(instance)

func add_chunk(num, chunkPosition):
	if (count < chunks_per_biome):
		var instance = chunks[num].instantiate()
		instance.position.x = chunkPosition
		add_child(instance)
	elif (count == chunks_per_biome):
		var instance = cavetoforest.instantiate()
		instance.position.x = chunkPosition
		add_child(instance)
	elif (count < chunks_per_biome * 2):
		var instance = forestchunks[num].instantiate()
		instance.position.x = chunkPosition
		add_child(instance)
	else:
		var instance = foresttocave.instantiate()
		instance.position.x = chunkPosition
		add_child(instance)
	count = count + 1
	print("chunk ", count, " instantiated!")

func set_map_seed(map_seed: int):	
	rng.seed = map_seed
	spawn_starting_chunks()
