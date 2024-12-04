##
extends CharacterBody2D


const SPEED = 150.0
const DECELERATION = 0.1
const ACCELERATION = 0.1
const JUMP_VELOCITY = -260.0
const WALL_JUMP_PUSHBACK = 250
const WALL_SLIDE_GRAVITY = 100
const DECELERATE_ON_JUMP_RELEASE = 0.8
const FALL_GRAVITY = 1050
const COYOTE_TIMER_LENGTH = 0.1
const JUMP_BUFFER_TIME_LENGTH = 0.15
const DASH_SPEED = 2.4
const JUMP_DASHTIMER = 0.1

var fall_rate = DECELERATE_ON_JUMP_RELEASE
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
var lost_pop_up_template = preload("res://scenes/end_pop_up.tscn")

@onready var animated_sprite: Sprite2D = $Sprite2D
@onready var player: Sprite2D = $Sprite2D
@onready var coyoteTimer: Timer = $Timers/CoyoteTimer
@onready var dashTimer: Timer = $Timers/DashTimer
@onready var jumpBufferTimer: Timer = $Timers/JumpBufferTimer
@onready var dashCooldown: Timer = $"Timers/DashCooldown"
@onready var powerupManager = $PowerUpManager
@onready var rayCastRight = $GrapplingHookRayCasts/RayCastRight
@onready var rayCastLeft = $GrapplingHookRayCasts/RayCastLeft
@onready var raycastToObstacle = $GrapplingHookRayCasts/RayCastToObstacle
@onready var dashEffectTimer = $Timers/DashEffectTimer

var hostSprite = preload("res://assets/sprites/mine_bot_idle_sheet_5.png")

@export var player_input: PlayerInput
@export var player_id := 1:
	set(id):
		player_id = id
###



var attack_state : bool = false
var attack_count : int = 1
var attack_timer : int = 0
@onready var health = $Control/VBoxContainer/Control/TextureProgressBar
@onready var original_anim_tree = $AnimationTree
@onready var anim_tree = $AnimationTree.get("parameters/playback")
@onready var anim_player = $AnimationPlayer
@onready var character_name = $Control/VBoxContainer/Control2/Label

# Get the gravity from the project settings to be synced with RigidBody nodes.

func _ready():
	reset()

func _process(delta):
	check_health()
	set_animation()

func reset():
	set_physics_process(false)
	set_process(false)
	set_process_input(false)
	
	await get_tree().create_timer(5).timeout
	
	$AnimationTree.set_active(true)
	health.value = 100
	if get_multiplayer_authority() == (User.ID):
		$AnimationTree.set_active(true)
		$Camera2D.enabled = true
		character_name.text = User.user_name
		set_physics_process(true)
		set_process_input(true)
		set_process(true)
		set_player_name.rpc(User.user_name)
		global_position = Vector2(0, 0)
		if User.is_host:
			set_sprite.rpc()
	else:
		character_name.text = "Other player"
		set_physics_process(false)
		set_process(false)
		set_process_input(false)



@rpc("any_peer","call_remote","reliable")
func set_player_name(_name : String):
	await get_tree().create_timer(2).timeout
	character_name.text = _name

@rpc("any_peer","call_local","reliable")
func set_sprite():
	await get_tree().create_timer(2).timeout
	animated_sprite.texture = hostSprite

func check_health():
	if health.value <= 0:
		die.rpc()


###
func _physics_process(delta):
	if not is_on_floor():
		if coyoteJump and coyoteTimer.is_stopped():
			coyoteTimer.start(COYOTE_TIMER_LENGTH)
		if not isDashing:
			velocity.y += return_gravity() * delta
	else:
		coyoteJump = true
		coyoteTimer.stop()

	if Input.is_action_just_pressed("jump"):
		jump()
###
	# Variable Jump Height
	if !Input.is_action_pressed("jump") and velocity.y < 0:
		velocity.y *= fall_rate
	
	if is_on_wall_only() and Input.get_axis("move_left", "move_right"):
		wall_slide()
##
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = Input.get_axis("move_left", "move_right")
	if direction:
		if isDashing:
			velocity.x = move_toward(velocity.x, direction * SPEED * DASH_SPEED, SPEED * ACCELERATION)
		else:
			velocity.x = move_toward(velocity.x, direction * SPEED, SPEED * ACCELERATION)
		player.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED * DECELERATION)
	
	if Input.is_action_just_pressed("dash") and canDash:
		if !isDashing and direction:
			start_dash()

	var wasOnFloor = is_on_floor()
	move_and_slide()
	
	#Execute buffered jump
	if !wasOnFloor && is_on_floor():
		if jumpBuffered:
			jumpBuffered = false
			jump()

func set_animation():
	
	if Input.is_action_just_pressed("jump") :
		anim_tree.travel("jump")
		sync_animation.rpc("jump")
	elif Input.is_action_just_pressed("left_mouse"):
		attack_state = true
		attack_timer = Time.get_ticks_msec()
	elif Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right"):
		if is_on_floor() and not attack_state:
			anim_tree.travel("run")
			sync_animation.rpc("run")
	elif is_on_floor() and not attack_state:
		anim_tree.travel("idle")
		sync_animation.rpc("idle")

	if attack_state:
		if Time.get_ticks_msec() - attack_timer >= 600:
			attack_state = false
			attack_count = 1

@rpc("any_peer","call_local","reliable")
func die():
	$AnimationTree.set_active(false)
	anim_player.play("Dead")
	set_physics_process(false)
	set_process(false)
	if get_multiplayer_authority() == (User.ID):
		var lost_pop_up = lost_pop_up_template.instantiate()
		add_child(lost_pop_up)
	
	# reset()

@rpc("any_peer","call_remote","reliable")
func sync_animation(anim_name: StringName):
	anim_tree.travel(anim_name)


@rpc("any_peer","call_remote","reliable")
func sync_flip(dir : int):
	$Area2D.transform.x.x = dir

@rpc("any_peer","call_local","reliable")
func hit_received():
	anim_tree.start("Hurt", true)
	health.value -= 5

func _on_area_2d_body_entered(body):
	if body != self:
		body.hit_received.rpc()

##
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
	player.flip_h = true
	
func wall_slide():
	velocity.y = min(velocity.y, WALL_SLIDE_GRAVITY)

func start_dash():
	print("helloooo I'm dashing!")
	print(User.map_seed)
	isDashing = true
	canDash = false
	dashTimer.start()
	dashCooldown.start()

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
	
func dash_cooldown_timeout():
	canDash = true
##
