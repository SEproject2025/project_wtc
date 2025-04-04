extends Node2D

@export  var chunks:       Array[PackedScene] = []
@export  var forestchunks: Array[PackedScene] = []
@export  var labchunks:    Array[PackedScene] = []
@onready var parallax_background = $"../CaveBackground"
var startingChunk: PackedScene = preload("res://chunks/starting_chunk.tscn")
var cavetoforest:  PackedScene = preload("res://chunks/Cavetoforest.tscn")
var foresttocave:  PackedScene = preload("res://chunks/Foresttocave.tscn")
var deathWall:     PackedScene = preload("res://scenes/death_wall.tscn")

var amnt = 3
var count = 0
var offset = 512 
var start_offset = -200
var rng = RandomNumberGenerator.new()

func _ready() -> void:
	rng.seed = User.current_lobby_seed
	spawn_starting_chunks()

func algorithm(n):
	if (count < 5):
		var num = rng.randi_range(0, chunks.size()-1)
		add_chunk(num, n)
	elif (count == 5):
		var num = rng.randi_range(0, forestchunks.size()-1)
		add_chunk(num, n)
	elif (count < 10):
		var num = rng.randi_range(0, forestchunks.size()-1)
		add_chunk(num, n)
	else:
		var num = rng.randi_range(0, forestchunks.size()-1)
		add_chunk(num, n)
		count = 0

func spawn_starting_chunks():
	for n in amnt:
		var instance = startingChunk.instantiate()
		instance.position.x = n*offset + start_offset
		add_child(instance)

func add_chunk(num, chunkPosition):
	if (count < 5):
		var instance = chunks[num].instantiate()
		instance.position.x = chunkPosition
		add_child(instance)
		print("yeet")
	elif (count == 5):
		var instance = cavetoforest.instantiate()
		instance.position.x = chunkPosition
		add_child(instance)
		print("forest")
	elif (count < 10):
		var instance = forestchunks[num].instantiate()
		instance.position.x = chunkPosition
		add_child(instance)
		print("yote")
	else:
		var instance = foresttocave.instantiate()
		instance.position.x = chunkPosition
		add_child(instance)
		print("heeheehoohoo")
	count = count + 1
	print(count)
