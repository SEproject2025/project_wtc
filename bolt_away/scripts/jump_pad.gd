extends Area2D 

const JUMP_PAD_STRENGTH = -600

func _on_body_entered(body):
	print("jump")
	body.velocity.y = JUMP_PAD_STRENGTH
