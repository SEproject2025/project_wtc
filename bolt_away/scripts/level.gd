extends Node2D

@export var chunks: Array[PackedScene] = []
var startingChunk: PackedScene = preload("res://chunks/starting_chunk.tscn")
var deathWall: PackedScene = preload("res://scenes/death_wall.tscn")

var amnt = 3
var offset = 256
var start_offset = -200
var rng = RandomNumberGenerator.new()

func _ready() -> void:
	MultiplayerManager.connect("host_joined", set_map_seed)
	MultiplayerManager.connect("client_joined", set_map_seed)
	spawn_starting_chunks()

func singleplayer_algorithm(n):
	var num = RandomNumberGenerator.new().randi_range(0, chunks.size()-1)
	add_chunk(num, n)

func multiplayer_algorithm(n):
	var num = rng.randi_range(0, chunks.size()-1)
	add_chunk(num, n)

func spawn_starting_chunks():
	for n in amnt:
		var instance = startingChunk.instantiate()
		instance.position.x = n*offset + start_offset
		add_child(instance)

func add_chunk(num, chunkPosition):
	var instance = chunks[num].instantiate()
	instance.position.x = chunkPosition
	add_child(instance)

func set_map_seed():
	rng.seed = MultiplayerManager.map_seed

