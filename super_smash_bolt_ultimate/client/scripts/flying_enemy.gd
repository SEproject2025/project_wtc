extends CharacterBody2D


const ROAMING_SPEED = 50
const CHASING_SPEED = 150

var dir: Vector2
var is_chase: bool = false

var target
var rng = RandomNumberGenerator.new()

@onready var timer = $Timer
@onready var animated_sprite = $AnimatedSprite2D

func _ready() -> void:
	if User.is_host:
		User.client.request_seed()
	User.client.generated_seed_received.connect(on_generated_seed_received)

func _physics_process(delta: float) -> void:
	move(delta)
	handle_animation()

func move(delta: float):
	if is_chase and target != null:
		var directionToTarget = global_position.direction_to(target.global_position)
		velocity = directionToTarget * CHASING_SPEED
		dir.x = directionToTarget.x
	else:
		velocity += dir * ROAMING_SPEED * delta
	move_and_slide()

func handle_animation():
	animated_sprite.play("fly")
	animated_sprite.flip_h = dir.x < 0

func _on_body_entered(body):
	if body.is_in_group("Players"):
		is_chase = true
		target = body

func _on_chase_radius_exited(body):
	print("HERE")
	if body.is_in_group("Players"):
		is_chase = false
		target = null
		velocity += dir * ROAMING_SPEED * get_process_delta_time()

func _on_damage_area_entered(body):
	if body.is_in_group("Players"):
		animated_sprite.play("attack")
		body.get_bumped(1 if body.animated_sprite.flip_h else -1)
		# body.hit_received.rpc()

func _on_killzone_area_entered(body):
	if body.is_in_group("Players") and abs(body.velocity.x) > Constants.Player.SPEED:
		queue_free()

func _on_timer_timeout():
	timer.wait_time = choose([0.8, 1, 1.4])
	if !is_chase:
		dir = choose([Vector2.RIGHT, Vector2.UP, Vector2.LEFT, Vector2.DOWN])

func on_generated_seed_received(generated_seed: int):
	rng.seed = generated_seed

func choose(array):
	return array[rng.randi_range(0, array.size() - 1)]
