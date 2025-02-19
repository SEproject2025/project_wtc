extends CharacterBody2D
class_name MultiplayerPlayer

const PLAYER = Constants.Player



var fall_rate = PLAYER.DECELERATE_ON_JUMP_RELEASE
var bumped: bool = false
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var coyoteJump: bool = true
var isDashing: bool = false
var canDash: bool = true
var jumpBuffered: bool = false
var wallJumping: bool = false
var jumpReleased: bool = false
var _is_on_floor: bool = true
var alive: bool = true
var grappleToPosition: Vector2
var targetPlayer
var isGrappling: bool = false
var isSlipping: bool = false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var coyoteTimer: Timer = $Timers/CoyoteTimer
@onready var dashTimer: Timer = $Timers/DashTimer
@onready var jumpBufferTimer: Timer = $Timers/JumpBufferTimer
@onready var dashCooldown: Timer = $"Timers/DashCooldown"
@onready var powerupManager = $PowerUpManager
@onready var rayCastRight = $GrapplingHookRayCasts/RayCastRight
@onready var rayCastLeft = $GrapplingHookRayCasts/RayCastLeft
@onready var raycastToObstacle = $GrapplingHookRayCasts/RayCastToObstacle
@onready var dashEffectTimer = $Timers/DashEffectTimer
@onready var oilSpillTimer = $Timers/OilSpillTimer


@export var player_input: PlayerInput
@export var player_id := 1:
	set(id):
		player_id = id


func _enter_tree():
	$".".set_multiplayer_authority(str(name).to_int())

func _ready():
	if multiplayer.get_unique_id() == str(name).to_int():
		$Camera2D.make_current()
	else:
		$Camera2D.enabled = false 

func _apply_animations(_delta):
	var direction = player_input.input_direction
	
	# flip player
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true
	
	# player animations
	if _is_on_floor:
		if direction == 0:
			animated_sprite.play("idle")
		else:
			animated_sprite.play("run")
	else:
		animated_sprite.play("jump")

func _apply_movement_from_input(delta):
	if not is_on_floor():
		if coyoteJump or coyoteTimer.is_stopped():
			coyoteTimer.start(PLAYER.COYOTE_TIMER_LENGTH)
		if not isDashing:
			velocity.y += return_gravity() * delta
	else:
		coyoteJump = true
		coyoteTimer.stop()
		
	if player_input.input_jump:
		if jumpReleased:
			jump()
			jumpReleased = false
		if !is_on_floor():
			coyoteJump = false
	
	if !player_input.input_jump:
		if velocity.y < 0:
			velocity.y *= fall_rate
		jumpReleased = true
	
	if is_on_wall_only() and player_input.input_direction:
		wall_slide()
		
	# the input direction, -1, 0, 1
	var direction = player_input.input_direction
	
	# player movement
	if isSlipping:
			if isDashing or abs(velocity.x) > PLAYER.SPEED:
				velocity.x = lerp(velocity.x, velocity.x * PLAYER.OIL_SLIP_SPEED, PLAYER.OIL_SLIP_SPEED)
			else:
				velocity.x = move_toward(velocity.x, direction * PLAYER.SPEED * PLAYER.OIL_SLIP_SPEED, PLAYER.SPEED * PLAYER.ACCELERATION * PLAYER.OIL_SLIP_SPEED)
	elif isDashing:
		if not direction:
			var dashDirection = -1 if animated_sprite.flip_h else 1
			velocity.x = move_toward(velocity.x, dashDirection * PLAYER.SPEED * PLAYER.DASH_SPEED, PLAYER.SPEED * PLAYER.ACCELERATION * PLAYER.DASH_SPEED)
		else:
			velocity.x = move_toward(velocity.x, direction * PLAYER.SPEED * PLAYER.DASH_SPEED, PLAYER.SPEED * PLAYER.ACCELERATION * PLAYER.DASH_SPEED)
	elif isGrappling:
		var directionToTarget = (grappleToPosition - global_position).normalized()
		velocity += directionToTarget * PLAYER.GRAPPLING_HOOK_SPEED * delta
	elif direction:
		velocity.x = move_toward(velocity.x, direction * PLAYER.SPEED, PLAYER.SPEED * PLAYER.ACCELERATION)
		animated_sprite.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, PLAYER.SPEED * PLAYER.DECELERATION)
	

	if player_input.input_dash and canDash:
		if !isDashing:
			start_dash()

	if player_input.input_use_powerup and !powerupManager.is_jetpack_active:
		powerupManager.use_powerup()
	
	if powerupManager.is_jetpack_active:
		if player_input.input_use_powerup and powerupManager.jetpack_fuel > 0:
			velocity.y = PLAYER.JETPACK_VELOCITY
			powerupManager.jetpack_fuel -= PLAYER.JETPACK_FUEL_CONSUMPTION * delta
		if powerupManager.jetpack_fuel <= 0:
			powerupManager.deactivate_jetpack()


	if isGrappling:
		queue_redraw()
		var directionToTarget = (grappleToPosition - global_position).normalized()
		velocity += directionToTarget * PLAYER.GRAPPLING_HOOK_SPEED * delta
		MultiplayerManager.rpc("update_grappling_hook", global_position, grappleToPosition)

		if global_position.distance_to(grappleToPosition) < 10 or global_position > grappleToPosition:
			stop_grappling_hook()

	if MultiplayerManager.drawGrapplingHook or MultiplayerManager.redraw_queue:
		MultiplayerManager.redraw_queue = false
		queue_redraw()
		
	var wasOnFloor = is_on_floor()

	move_and_slide()
	
	if !wasOnFloor and is_on_floor():
		if jumpBuffered:
			jumpBuffered = false
			jump()

func _physics_process(delta):
	if is_multiplayer_authority():
		if not alive && is_on_floor():
			_set_alive()
		
		_is_on_floor = is_on_floor()
		if MultiplayerManager.isBeingPulled:
			pull_to_target(MultiplayerManager.pull_target_position, delta)
			queue_redraw()
		else:
			_apply_movement_from_input(delta)

func _process(delta):
	if not multiplayer.is_server() || MultiplayerManager.host_mode_enabled:
		_apply_animations(delta)

func set_dead():
	alive = false
	$CollisionShape2D.set_deferred("disabled", true)
	$Timers/RespawnTimer.start()

func _respawn():
	position = MultiplayerManager.respawn_point
	$CollisionShape2D.set_deferred("disabled", false)

func _set_alive():
	alive = true
	Engine.time_scale = 1.0
	
func jump():
	if is_on_floor() or coyoteJump:
		velocity.y = PLAYER.JUMP_VELOCITY
		coyoteJump = false
	else:
		if !jumpBuffered:
			jumpBuffered = true
			jumpBufferTimer.start(PLAYER.JUMP_BUFFER_TIME_LENGTH)
	
	if is_on_wall_only():
		wall_jump()

func wall_jump():
	velocity = Vector2(get_wall_normal().x * PLAYER.WALL_JUMP_PUSHBACK, PLAYER.JUMP_VELOCITY)

func wall_slide():
	velocity.y = min(velocity.y, PLAYER.WALL_SLIDE_GRAVITY)
	
func start_dash():
	isDashing = true
	canDash = false
	dashTimer.start()
	dashCooldown.start()
	dashEffectTimer.start()

func dash_timeout():
	isDashing = false
	dashEffectTimer.stop()

func coyote_timeout():
	coyoteJump = false

func jump_buffer_timeout():
	jumpBuffered = false

func return_gravity():
	var gravity = get_gravity().y
	if velocity.y <= 0 and bumped == true:
		gravity /= 1.25
		fall_rate = 1
	elif velocity.y >= 0 and bumped == true:
		bumped = false
		fall_rate = PLAYER.DECELERATE_ON_JUMP_RELEASE
	return gravity

func dash_cooldown_timeout():
	canDash = true

func oil_slip():
	if !isSlipping:
		isSlipping = true
		oilSpillTimer.start()

func oilspill_timer_timeout():
	isSlipping = false


func pull_to_target(targetPosition: Vector2, delta: float):
	var directionBackToTarget = (targetPosition - global_position).normalized()
	velocity += directionBackToTarget * PLAYER.GRAPPLING_HOOK_SPEED * delta

	if global_position.distance_to(targetPosition) < PLAYER.GRAPPLING_HOOK_STOP_DISTANCE or rayCastLeft.is_colliding():
		MultiplayerManager.isBeingPulled = false

	move_and_slide()

func _draw() -> void:
	if isGrappling:
		draw_line(PLAYER.CENTER_OF_SPRITE, to_local(grappleToPosition), Color.BLACK, PLAYER.GRAPPLING_HOOK_WIDTH)
	if MultiplayerManager.drawGrapplingHook:
		draw_line(to_local(MultiplayerManager.grappleThrowerPosition), to_local(MultiplayerManager.grappleTargetPosition), Color.BLACK, PLAYER.GRAPPLING_HOOK_WIDTH)


func fire_grappling_hook():
	targetPlayer = get_leading_player()
	if targetPlayer:
		grappleToPosition = targetPlayer.global_position + PLAYER.CENTER_OF_SPRITE
		rayCastRight.look_at(grappleToPosition)
		isGrappling = true
		MultiplayerManager.rpc_id(targetPlayer.name.to_int(), "pull_to_target", global_position)
	else:
		if raycastToObstacle.is_colliding():
			grappleToPosition = raycastToObstacle.get_collision_point()
			isGrappling = true
	MultiplayerManager.rpc("draw_grappling_hook", global_position, grappleToPosition)

func stop_grappling_hook():
	isGrappling = false
	targetPlayer = null
	grappleToPosition = Vector2.ZERO
	MultiplayerManager.rpc("stop_grappling_hook")


func get_leading_player() -> Node2D:
	var closestPlayer = null
	var closestDistance = null

	for player in get_tree().get_current_scene().get_node("Players").get_children():
		if player.name != self.name and player.global_position.x > global_position.x:
			var distance = global_position.distance_to(player.global_position)
			if !closestDistance or distance < closestDistance:
				closestDistance = distance
				closestPlayer = player

	return closestPlayer

func _on_dash_effect_timer_timeout():
	var playerCopy = animated_sprite.duplicate()
	get_tree().get_root().add_child(playerCopy)
	playerCopy.global_position = global_position + PLAYER.CENTER_OF_SPRITE
	
	var effectTime = dashTimer.wait_time / 3
	await get_tree().create_timer(effectTime).timeout
	playerCopy.modulate.a = 0.4

	await get_tree().create_timer(effectTime).timeout
	playerCopy.modulate.a = 0.2

	await get_tree().create_timer(effectTime).timeout
	playerCopy.queue_free()
