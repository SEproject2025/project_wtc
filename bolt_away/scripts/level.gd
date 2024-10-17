extends Node2D

@export var chunks: Array[PackedScene] = []
var startingChunk: PackedScene = preload("res://chunks/starting_chunk.tscn")
var deathWall: PackedScene = preload("res://scenes/death_wall.tscn")

var amnt = 3
var offset = 256
var start_offset = -200
var rng = RandomNumberGenerator.new()

func _ready() -> void:
	MultiplayerManager.connect("multiplayer_mode_changed", _on_multiplayer_mode_changed)
	MultiplayerManager.connect("player_joined", player_joined)
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

func _on_multiplayer_mode_changed(_multiplayer_enabled: bool):
	rng.seed = MultiplayerManager.map_seed

func player_joined(_multiplayer_enabled: bool):
	if !multiplayer.is_server():
		rng.seed = MultiplayerManager.map_seed


