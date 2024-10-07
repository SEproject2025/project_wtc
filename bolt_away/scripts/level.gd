extends Node2D

@export var chunks: Array[PackedScene] = []

var amnt = 3

var offset = 256
var rng = RandomNumberGenerator.new()
var executed = true

func _ready() -> void:
	MultiplayerManager.connect("multiplayer_mode_changed", _on_multiplayer_mode_changed)
	MultiplayerManager.connect("player_joined", player_joined)
	spawn_default_chunks()

func spawnChunk(n):
	if MultiplayerManager.multiplayer_mode_enabled:
		print("Chunk spawned")
		var num = rng.randi_range(0, chunks.size()-1)
		if multiplayer.is_server():
			print("server seed" + str(rng.seed))
			print("server chunk: " + str(num))
		else:
			print("client seed" + str(rng.seed))
			print("client chunk: " + str(num))
		var instance = chunks[num].instantiate()
		instance.position.x = n
		add_child(instance)
	else:
		var num = RandomNumberGenerator.new().randi_range(0, chunks.size()-1)
		var instance = chunks[num].instantiate()
		instance.position.x = n
		add_child(instance)

func _on_multiplayer_mode_changed(multiplayer_enabled: bool):
	rng.seed = MultiplayerManager.map_seed

func player_joined(multiplayer_enabled: bool):
	if !multiplayer.is_server():
		rng.seed = MultiplayerManager.map_seed
		print("set client seed" + str(MultiplayerManager.map_seed))


func spawn_default_chunks():
	var defaultRng = RandomNumberGenerator.new()
	defaultRng.seed = 10
	for n in amnt:
		var num = defaultRng.randi_range(0, chunks.size()-1)
		var instance = chunks[num].instantiate()
		instance.position.x = n*offset
		add_child(instance)
