extends Node2D

@export var LAUNCH_POWER = 0
var angle: float
var velocity_x
var velocity_y

func _ready():
	angle = (rotation_degrees * -1 ) + 90
	velocity_x = LAUNCH_POWER * cos(angle * (PI/180))
	velocity_y = -1 * (LAUNCH_POWER * sin(angle * (PI/180)))

func _on_area_2d_body_entered(body):
	body.bumped     = true
	body.coyoteJump = false
	body.velocity.x = velocity_x
	body.velocity.y = velocity_y
