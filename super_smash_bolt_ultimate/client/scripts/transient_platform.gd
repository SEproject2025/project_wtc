extends Node2D

const FORCE_DOWNWARD      = 600.0
const PRESSURE_POINT      = 16.0
const MAX_TIMER_ITERATION = 3

var   timer_iteration     = 1 #Humans never count from zero!

@onready var gracious_delay: Timer = $SQUEEEEK

func _on_area_2d_left_body_entered(_body: Node2D) -> void:
	$RigidBody2D.apply_force(Vector2(0.0, FORCE_DOWNWARD), Vector2(-1 * PRESSURE_POINT, 0.0))
	$RigidBody2D.call_deferred("set_freeze_enabled", false)
	gracious_delay.start()

func _on_area_2d_2_middle_body_entered(_body: Node2D) -> void:
	$RigidBody2D.apply_force(Vector2(0.0, FORCE_DOWNWARD), Vector2(0.0, 0.0))
	$RigidBody2D.call_deferred("set_freeze_enabled", false)
	gracious_delay.start()

func _on_area_2d_right_body_entered(_body: Node2D) -> void:
	$RigidBody2D.apply_force(Vector2(0.0, FORCE_DOWNWARD), Vector2(PRESSURE_POINT, 0.0))
	$RigidBody2D.call_deferred("set_freeze_enabled", false)
	gracious_delay.start()

func _on_squeeeek_timeout() -> void:
	if timer_iteration <= MAX_TIMER_ITERATION:
		if(timer_iteration == 1):
			$RigidBody2D.gravity_scale = 1
		timer_iteration += 1
	else:
		gracious_delay.stop()
		$RigidBody2D.queue_free()
