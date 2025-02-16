extends Node2D

#THIS IS THE WALL

const FORCE_DOWNWARD      = 600.0
const PRESSURE_POINT      = 16.0
const MAX_TIMER_ITERATION = 3

var   timer_iteration     = 1 #Humans never count from zero!

@onready var gracious_delay: Timer = $SQUEEEEK

func _on_area_2d_left_body_entered(body: Node2D) -> void:
	if(body.isDashing == true):
		$RigidBodyUpperLeft.call_deferred("set_freeze_enabled", false)
		$RigidBodyUpperLeft.apply_force(Vector2(body.velocity.x, 0.0), Vector2(0.0, 0.0))
		$RigidBodyLowerRight.call_deferred("set_freeze_enabled", false)
		$RigidBodyLowerRight.apply_force(Vector2(body.velocity.x, 0.0), Vector2(0.0, 0.0))
		$RigidBodyUpperRight.call_deferred("set_freeze_enabled", false)
		$RigidBodyUpperRight.apply_force(Vector2(body.velocity.x, 0.0), Vector2(0.0, 0.0))
		#gracious_delay.start()



func _on_squeeeek_timeout() -> void:
	if timer_iteration <= MAX_TIMER_ITERATION:
		if(timer_iteration == 1):
			$RigidBody2D.gravity_scale = 1
		timer_iteration += 1
	else:
		gracious_delay.stop()
		$RigidBody2D.queue_free()
