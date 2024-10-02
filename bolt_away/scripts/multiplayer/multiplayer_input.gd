class_name PlayerInput extends Node

var input_direction = 0
var input_jump = 0

func _ready():
	
	if not is_multiplayer_authority():
		return
	
	input_direction = Input.get_axis("move_left", "move_right")

func _physics_process(delta):
	
	if not is_multiplayer_authority():
		return
		
	input_direction = Input.get_axis("move_left", "move_right")

func _process(delta):
	
	if not is_multiplayer_authority():
		return
		
	input_jump = Input.get_action_strength("jump")
