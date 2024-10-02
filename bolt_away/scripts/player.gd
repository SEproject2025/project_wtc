extends CharacterBody2D

const SPEED = 150.0
const DECELERATION = 0.1
const ACCELERATION = 0.1
const JUMP_VELOCITY = -260.0
const WALL_JUMP_PUSHBACK = 200
const WALL_SLIDE_GRAVITY = 100
const DECELERATE_ON_JUMP_RELEASE = 0.8
const FALL_GRAVITY = 1300
const COYOTE_TIMER_LENGTH = 0.1
const JUMP_BUFFER_TIME_LENGTH = 0.15
const DASH_SPEED = 2.4

var canJump: bool = true
var isDashing: bool = false
var jumpBuffered: bool = false
var wallJumping: bool = false

@onready var coyoteTimer: Timer = $CoyoteTimer
@onready var player: AnimatedSprite2D = $AnimatedSprite2D
@onready var dashTimer: Timer = $DashTimer
@onready var jumpBufferTimer: Timer = $JumpBufferTimer

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		if canJump and coyoteTimer.is_stopped():
			coyoteTimer.start(COYOTE_TIMER_LENGTH)
		velocity.y += return_gravity() * delta
	else:
		canJump = true
		coyoteTimer.stop()
	
	if Input.is_action_just_pressed("jump"):
		jump()

	# Variable Jump Height
	if !Input.is_action_pressed("jump") and velocity.y < 0:
		velocity.y *= DECELERATE_ON_JUMP_RELEASE
	
	if is_on_wall_only() and Input.get_axis("move_left", "move_right"):
		wall_slide()
	

	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		if isDashing:
			velocity.x = move_toward(velocity.x, direction * SPEED * DASH_SPEED, SPEED * ACCELERATION)
		else:
			velocity.x = move_toward(velocity.x, direction * SPEED, SPEED * ACCELERATION)
		player.flip_h = direction > 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED * DECELERATION)
	
	if Input.is_action_just_pressed("dash"):
		if !isDashing and direction:
			start_dash()

	var wasOnFloor = is_on_floor()
	move_and_slide()
	
	#Execute buffered jump
	if !wasOnFloor && is_on_floor():
		if jumpBuffered:
			jumpBuffered = false
			jump()
			
func jump():
	if is_on_floor() or canJump:
		velocity.y = JUMP_VELOCITY
		canJump = false
	else:
		if !jumpBuffered:
			jumpBuffered = true
			jumpBufferTimer.start(JUMP_BUFFER_TIME_LENGTH)
			
	if is_on_wall_only() and Input.get_axis("move_left", "move_right"):
		wall_jump()
		
func wall_jump():
	velocity = Vector2(get_wall_normal().x * WALL_JUMP_PUSHBACK, JUMP_VELOCITY)
	player.flip_h = true
	
func wall_slide():
	velocity.y = min(velocity.y, WALL_SLIDE_GRAVITY)

func start_dash():
	isDashing = true
	dashTimer.start()

func return_gravity():
	return get_gravity().y if velocity.y < 0 else FALL_GRAVITY
	
func coyote_timeout():
	canJump = false

func jump_buffer_timeout():
	jumpBuffered = false
  	
func dash_timeout():
	isDashing = false
	
