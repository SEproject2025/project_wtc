extends Node2D

const MAX_TIMER_ITERATION = 5
const COLLISION_PHASE_OUT = 4
const HEAD_BOUNCE         = -200
const HEAD_TORQUE         = 21
const TORSO_BOUNCE        = -100
const TORSO_TORQUE        = 3

var   timer_iteration     = 1

@onready var head_color: Sprite2D  = $Head/CollisionShape2D/Sprite2D
@onready var torso_color: Sprite2D = $Torso/CollisionShape2D/Sprite2D
@onready var foot_color: Sprite2D  = $Foot/CollisionShape2D/Sprite2D
@onready var despawn_timer: Timer  = $Despawn_timer

func _ready() -> void:
	despawn_timer.start()

func set_momentum(player_velocity_vector):
	$Head.apply_impulse(player_velocity_vector)
	$Head.apply_impulse(Vector2(HEAD_TORQUE,0), Vector2(0, HEAD_BOUNCE))
	$Torso.apply_impulse(player_velocity_vector)
	$Torso.apply_impulse(Vector2(TORSO_TORQUE,0), Vector2(0, TORSO_BOUNCE))
	$Foot.apply_impulse(player_velocity_vector)

func set_sprite(sprite_received):
	head_color.texture.atlas  = sprite_received
	torso_color.texture.atlas = sprite_received
	foot_color.texture.atlas  = sprite_received

func _on_despawn_timer_timeout() -> void:
	if(timer_iteration <= MAX_TIMER_ITERATION):
		if(timer_iteration == COLLISION_PHASE_OUT):
			$Head.collision_mask  = 4
			$Torso.collision_mask = 4
			$Foot.collision_mask  = 4
		timer_iteration += 1
	else:
		despawn_timer.stop()
		queue_free()
