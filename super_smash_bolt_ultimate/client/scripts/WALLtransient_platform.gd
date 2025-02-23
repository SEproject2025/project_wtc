extends Node2D

#THIS IS THE WALL

const FORCE_DOWNWARD      = 600.0
const PRESSURE_POINT      = 16.0
const MAX_TIMER_ITERATION = 9
const IDEAL_TIMER_ITERATION = 3
const WHAT_USED_TO_BE_BODY_DOT_VELOCITY_DOT_X = 215.0

var   timer_iteration     = 1 #Humans never count from zero!

@onready var gracious_delay: Timer = $SQUEEEEK

#@rpc("any_peer", "call_remote", "reliable")
#func get_bumped(direction: int):
		#$RigidBodyUpperLeft.call_deferred("set_freeze_enabled", false)
		#$RigidBodyUpperLeft.apply_force(Vector2(WHAT_USED_TO_BE_BODY_DOT_VELOCITY_DOT_X, 0.0), Vector2(0.0, 0.0))
		#$RigidBodyUpperLeft.CollisionShape2D.Layer = 3
		#$RigidBodyLowerRight.call_deferred("set_freeze_enabled", false)
		#$RigidBodyLowerRight.apply_force(Vector2(WHAT_USED_TO_BE_BODY_DOT_VELOCITY_DOT_X, 0.0), Vector2(0.0, 0.0))
		#$RigidBodyUpperRight.call_deferred("set_freeze_enabled", false)
		#$RigidBodyUpperRight.apply_force(Vector2(WHAT_USED_TO_BE_BODY_DOT_VELOCITY_DOT_X, 0.0), Vector2(0.0, 0.0))

func _on_area_2d_left_body_entered(body: Node2D) -> void:
	if(body.get_class() == "CharacterBody2D"):
		if(body.isDashing == true):
			$RigidBodyUpperLeft.call_deferred("set_freeze_enabled", false)
			$RigidBodyUpperLeft.apply_central_force(Vector2(body.velocity.x * -10.0, -300.0))#, Vector2(7.0, 9.0))
			$RigidBodyUpperLeft.collision_layer = 4
			$RigidBodyLowerRight.call_deferred("set_freeze_enabled", false)
			$RigidBodyLowerRight.apply_central_force(Vector2(body.velocity.x * 40.0, 00000.0))
			$RigidBodyLowerRight.collision_layer = 4
			$RigidBodyUpperRight.call_deferred("set_freeze_enabled", false)
			$RigidBodyUpperRight.apply_central_force(Vector2(body.velocity.x * 40.0, -20000.0))
			$RigidBodyUpperRight.collision_layer = 4
			$Area2DLeft.queue_free()
			$Area2DRight.queue_free()
			gracious_delay.start()



func _on_squeeeek_timeout() -> void:
	if timer_iteration <= MAX_TIMER_ITERATION:
		if(timer_iteration == IDEAL_TIMER_ITERATION):
			$RigidBodyUpperLeft.collision_mask = 4
			$RigidBodyLowerRight.collision_mask = 4
			$RigidBodyUpperRight.collision_mask = 4
		timer_iteration += 1
	else:
		gracious_delay.stop()
		$RigidBodyUpperLeft.queue_free()
		$RigidBodyLowerRight.queue_free()
		$RigidBodyUpperRight.queue_free()
