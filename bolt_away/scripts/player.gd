extends CharacterBody2D

const SPEED = 200.0
const DECELERATION = 0.1
const ACCELERATION = 0.1
const JUMP_VELOCITY = -260.0
const WALL_JUMP_PUSHBACK = 200
const WALL_SLIDE_GRAVITY = 100
const DECELERATE_ON_JUMP_RELEASE = 0.8
const FALL_GRAVITY = 1300.0
const COYOTE_TIMER_LENGTH = 0.1
const JUMP_BUFFER_TIME_LENGTH = 0.15
const DASH_SPEED = 2.4
const JETPACK_VELOCITY = -200
const JETPACK_FUEL_CONSUMPTION = 25
const GRAPPLING_HOOK_SPEED = 1200.0
const CENTER_OF_SPRITE = Vector2(3,-10)
const OIL_SLIP_SPEED = 0.2

var fall_rate = DECELERATE_ON_JUMP_RELEASE
var bumped: bool = false
var coyoteJump: bool = true
var isDashing: bool = false
var jumpBuffered: bool = false
var wallJumping: bool = false
var canDash: bool = true
var isGrappling: bool = false
var isSlipping: bool = false
var grappleToPosition: Vector2


@onready var coyoteTimer: Timer = $Timers/CoyoteTimer
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var dashTimer: Timer = $Timers/DashTimer
@onready var jumpBufferTimer: Timer = $Timers/JumpBufferTimer
@onready var dashCooldown: Timer = $"Timers/DashCooldown"
@onready var powerupManager = $PowerUpManager
@onready var raycastToObstacle = $"RayCastToObstacle"
@onready var dashEffectTimer = $Timers/DashEffectTimer
@onready var oilSpillTimer = $Timers/OilSpillTimer


func _process(_delta):
	#Use powerup (Don't call if jetpack is active)
	if Input.is_action_just_pressed("use_powerup") and !powerupManager.is_jetpack_active:
		powerupManager.use_powerup()


func _draw() -> void:
	if isGrappling:
		draw_line(Vector2(3, -8), to_local(grappleToPosition), Color.BLACK, 1.5)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		if coyoteJump and coyoteTimer.is_stopped():
			coyoteTimer.start(COYOTE_TIMER_LENGTH)
		if not isDashing:
			velocity.y += return_gravity() * delta
	else:
		coyoteJump = true
		coyoteTimer.stop()

	if powerupManager.is_jetpack_active:
		if Input.is_action_pressed("use_powerup") and powerupManager.jetpack_fuel > 0:
			velocity.y = JETPACK_VELOCITY
			powerupManager.jetpack_fuel -= JETPACK_FUEL_CONSUMPTION * delta
		if powerupManager.jetpack_fuel <= 0:
			powerupManager.deactivate_jetpack()
	
	if Input.is_action_just_pressed("jump"):
		jump()

	# Variable Jump Height
	if !Input.is_action_pressed("jump") and velocity.y < 0:
		velocity.y *= fall_rate
	
	if is_on_wall_only() and Input.get_axis("move_left", "move_right"):
		wall_slide()
	

	var direction := Input.get_axis("move_left", "move_right")

	if isSlipping:
			if isDashing or abs(velocity.x) > SPEED:
				velocity.x = lerp(velocity.x, velocity.x * OIL_SLIP_SPEED, OIL_SLIP_SPEED)
			else:
				velocity.x = move_toward(velocity.x, direction * SPEED * OIL_SLIP_SPEED, SPEED * ACCELERATION * OIL_SLIP_SPEED)
	elif isDashing:
		if not direction:
			var dashDirection = -1 if animated_sprite.flip_h else 1
			velocity.x = move_toward(velocity.x, dashDirection * SPEED * DASH_SPEED, SPEED * ACCELERATION * DASH_SPEED)
		else:
			velocity.x = move_toward(velocity.x, direction * SPEED * DASH_SPEED, SPEED * ACCELERATION * DASH_SPEED)
	elif direction:
		velocity.x = move_toward(velocity.x, direction * SPEED, SPEED * ACCELERATION)
		animated_sprite.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED * DECELERATION)
	
	if Input.is_action_just_pressed("dash") and canDash:
		if !isDashing:
			start_dash()

	if isGrappling:
		queue_redraw()
		var directionToTarget = (grappleToPosition - global_position).normalized()
		velocity += directionToTarget * GRAPPLING_HOOK_SPEED * delta

		if global_position.distance_to(grappleToPosition) < 10 or global_position > grappleToPosition:
			stop_grappling_hook()

	var wasOnFloor = is_on_floor()
	move_and_slide()
	
	#Execute buffered jump
	if !wasOnFloor && is_on_floor():
		if jumpBuffered:
			jumpBuffered = false
			jump()
			
func jump():
	if is_on_floor() or coyoteJump:
		velocity.y = JUMP_VELOCITY
		coyoteJump = false

	else:
		if !jumpBuffered:
			jumpBuffered = true
			jumpBufferTimer.start(JUMP_BUFFER_TIME_LENGTH)
			
	if is_on_wall_only():
		wall_jump()
		
func wall_jump():
	velocity = Vector2(get_wall_normal().x * WALL_JUMP_PUSHBACK, JUMP_VELOCITY)
	animated_sprite.flip_h = true
	
func wall_slide():
	velocity.y = min(velocity.y, WALL_SLIDE_GRAVITY)

func start_dash():
	isDashing = true
	canDash = false
	dashTimer.start()
	dashCooldown.start()
	dashEffectTimer.start()

func return_gravity():
	var gravity = get_gravity().y
	if velocity.y <= 0 and bumped == true:
		gravity /= 1.25
		fall_rate = 1
	elif velocity.y >= 0 and bumped == true:
		bumped = false
		fall_rate = DECELERATE_ON_JUMP_RELEASE
	return gravity
	
func coyote_timeout():
	coyoteJump = false

func jump_buffer_timeout():
	jumpBuffered = false
  	
func dash_timeout():
	isDashing = false
	dashEffectTimer.stop()
	
func dash_cooldown_timeout():
	canDash = true

func oil_slip():
	if !isSlipping:
		isSlipping = true
		oilSpillTimer.start()

func oilspill_timer_timeout():
	isSlipping = false

func fire_grappling_hook():
	if raycastToObstacle.is_colliding():
		grappleToPosition = raycastToObstacle.get_collision_point()
		isGrappling = true

func stop_grappling_hook():
	isGrappling = false
	grappleToPosition = Vector2.ZERO

func _on_dash_effect_timer_timeou():
	var playerCopy = animated_sprite.duplicate()
	get_tree().get_root().add_child(playerCopy)
	playerCopy.global_position = global_position + CENTER_OF_SPRITE
	
	var effectTime = dashTimer.wait_time / 3
	await get_tree().create_timer(effectTime).timeout
	playerCopy.modulate.a = 0.4

	await get_tree().create_timer(effectTime).timeout
	playerCopy.modulate.a = 0.2

	await get_tree().create_timer(effectTime).timeout
	playerCopy.queue_free()


	
