extends "res://scripts/player_character.gd"

func _ready():
	super._ready()
	set_process_input(false)
	set_physics_process(false)
	set_process_unhandled_input(false)
	
	_set_invisible.rpc()

@rpc("any_peer", "call_local", "reliable")
func _set_invisible():
	visible = false
	$CollisionShape2D.disabled = true
	alive = false
