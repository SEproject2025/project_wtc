extends CharacterBody2D


@onready var animated_sprited = $AnimatedSprite2D
@onready var animationPlayer = $"AnimationPlayer"

const JUMP_POWER = -400

func _physics_process(delta: float) -> void:
		if is_on_wall() and is_on_floor():
			velocity.y = JUMP_POWER
		else: 
			velocity.y += get_gravity().y * delta
	
		move_and_slide()
	
@rpc("any_peer","call_local","reliable")
func move(direction, speed):
		velocity.x = direction * speed
		update_flip(direction)

func handle_animation():
	if velocity.x != 0:
		animated_sprited.play("walk")
	else:
		animated_sprited.play("idle")

func update_flip(direction):
	if abs(direction) == direction:
		animated_sprited.flip_h = false
	else:
		animated_sprited.flip_h = true

func check_for_self(node):
	return node == self

@rpc("any_peer","call_local","reliable")
func play_animation(anim_name):
	animationPlayer.play(anim_name)