extends CharacterBody2D


@onready var animated_sprited = $AnimatedSprite2D
@onready var animationPlayer = $"AnimationPlayer"
@onready var hurtAnimationPlayer = $HurtAnimationPlayer

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

func on_body_entered(body):
	if body.is_in_group("Players"):
		body.get_bumped(1 if body.animated_sprite.flip_h else -1)
		body.hit_received.rpc()

func on_killzone_entered(body):
	if body.is_in_group("Players"):
		die.rpc()

@rpc("any_peer","call_local","reliable")
func die():
	hurtAnimationPlayer.play("hit_flash")
	await get_tree().create_timer(0.2).timeout
	queue_free()
