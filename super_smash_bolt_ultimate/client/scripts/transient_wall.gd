extends Node2D

#THIS IS THE WALL

const BREAKUP_FORCE_X       = 2000.0
const BREAKUP_FORCE_Y       = -4000.0
const FORCE_DOWNWARD        = 600.0
const PRESSURE_POINT        = 16.0
const MAX_TIMER_ITERATION   = 9
const IDEAL_TIMER_ITERATION = 3

var   timer_iteration       = 1 #Humans never count from zero!

@onready var gracious_delay: Timer = $CRUMBLE


func _on_area_2d_left_body_entered(body: Node2D) -> void:
	if(body.get_class() == "CharacterBody2D" and body.isDashing == true):
		crumblings()

func crumblings():
	$SolidBlock.queue_free()
	$RigidBodyUpperLeft.call_deferred("set_freeze_enabled", false)
	$RigidBodyUpperLeft.apply_central_force(Vector2(-1.0 * BREAKUP_FORCE_X, BREAKUP_FORCE_Y))
	$RigidBodyUpperLeft.collision_layer = 4
	$RigidBodyLowerRight.call_deferred("set_freeze_enabled", false)
	$RigidBodyLowerRight.apply_central_force(Vector2(BREAKUP_FORCE_X * 4.0, 0.0))
	$RigidBodyLowerRight.collision_layer = 4
	$RigidBodyUpperRight.call_deferred("set_freeze_enabled", false)
	$RigidBodyUpperRight.apply_force(Vector2(BREAKUP_FORCE_X * 2.0, BREAKUP_FORCE_Y * 5.0),
									 Vector2(1.0, 0.0))
	$RigidBodyUpperRight.collision_layer = 4
	$Area2DLeft.queue_free()
	gracious_delay.start()

func _on_squeeeek_timeout() -> void:
	if timer_iteration <= MAX_TIMER_ITERATION:
		if(timer_iteration == IDEAL_TIMER_ITERATION):
			$RigidBodyUpperLeft.collision_mask  = 4
			$RigidBodyLowerRight.collision_mask = 4
			$RigidBodyUpperRight.collision_mask = 4
		timer_iteration += 1
	else:
		gracious_delay.stop()
		$RigidBodyUpperLeft.queue_free()
		$RigidBodyLowerRight.queue_free()
		$RigidBodyUpperRight.queue_free()
		
@rpc("any_peer", "call_remote")
func synchronized_crumblings():
	crumblings()
