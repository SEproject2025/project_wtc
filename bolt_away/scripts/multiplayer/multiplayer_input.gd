class_name PlayerInput 
extends Node

var input_direction: float = 0
var input_jump: float = 0
var input_dash: float = 0

func _ready():
	
	if not is_multiplayer_authority():
		return
	
	input_direction = Input.get_axis("move_left", "move_right")

func _physics_process(_delta):
	
	if not is_multiplayer_authority():
		return
		
	input_direction = Input.get_axis("move_left", "move_right")

func _process(_delta):
	
	if not is_multiplayer_authority():
		return
		
	input_jump = Input.get_action_strength("jump")
	input_dash = Input.get_action_strength("dash")
