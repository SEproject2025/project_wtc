extends CharacterBody2D
class_name MultiplayerPlayer

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
const JETPACK_VELOCITY = -200
const JETPACK_FUEL_CONSUMPTION = 25
const GRAPPLING_HOOK_SPEED = 1000.0
const CENTER_OF_SPRITE = Vector2(3,-10) #Change if sprite changes
const GRAPPLING_HOOK_WIDTH = 1.5
const GRAPPLING_HOOK_STOP_DISTANCE = 10

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

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var coyoteTimer: Timer = $Timers/CoyoteTimer
@onready var dashTimer: Timer = $Timers/DashTimer
@onready var jumpBufferTimer: Timer = $Timers/JumpBufferTimer
@onready var dashCooldown: Timer = $"Timers/DashCooldown"
@onready var powerupManager = $PowerUpManager
@onready var navAgent = $NavigationAgent2D
@onready var rayCastRight = $GrapplingHookRayCasts/RayCastRight
@onready var rayCastLeft = $GrapplingHookRayCasts/RayCastLeft
@onready var raycastToObstacle = $GrapplingHookRayCasts/RayCastToObstacle

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
			coyoteTimer.start(COYOTE_TIMER_LENGTH)
		velocity.y += gravity * delta
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
			velocity.y *= DECELERATE_ON_JUMP_RELEASE
		jumpReleased = true
	
	if is_on_wall_only() and player_input.input_direction:
		wall_slide()
		
	# the input direction, -1, 0, 1
	var direction = player_input.input_direction
	
	# player movement
	if direction:
		if isDashing:
			velocity.x = move_toward(velocity.x, direction * SPEED * DASH_SPEED, SPEED * ACCELERATION)
		else:
			velocity.x = move_toward(velocity.x, direction * SPEED, SPEED * ACCELERATION)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED * DECELERATION)

	if player_input.input_dash and canDash:
		if !isDashing and direction:
			start_dash()

	if player_input.input_use_powerup and !powerupManager.is_jetpack_active:
		powerupManager.use_powerup()
	
	if powerupManager.is_jetpack_active:
		if player_input.input_use_powerup and powerupManager.jetpack_fuel > 0:
			velocity.y = JETPACK_VELOCITY
			powerupManager.jetpack_fuel -= JETPACK_FUEL_CONSUMPTION * delta
		if powerupManager.jetpack_fuel <= 0:
			powerupManager.deactivate_jetpack()

	if isGrappling:
		queue_redraw()
		var directionToTarget = (grappleToPosition - global_position).normalized()
		velocity += directionToTarget * GRAPPLING_HOOK_SPEED * delta
		MultiplayerManager.rpc("update_grappling_hook", global_position, grappleToPosition)

		if global_position.distance_to(grappleToPosition) < 10 or global_position > grappleToPosition or rayCastRight.is_colliding():
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
		velocity.y = JUMP_VELOCITY
		coyoteJump = false
	else:
		if !jumpBuffered:
			jumpBuffered = true
			jumpBufferTimer.start(JUMP_BUFFER_TIME_LENGTH)
	
	if is_on_wall_only() and velocity.y > 0:
		wall_jump()

func wall_jump():
	velocity = Vector2(get_wall_normal().x * WALL_JUMP_PUSHBACK, JUMP_VELOCITY)

func wall_slide():
	velocity.y = min(velocity.y, WALL_SLIDE_GRAVITY)
	
func start_dash():
	isDashing = true
	canDash = false
	dashTimer.start()
	dashCooldown.start()

func dash_timeout():
	isDashing = false

func coyote_timeout():
	coyoteJump = false

func jump_buffer_timeout():
	jumpBuffered = false

func return_gravity():
	return gravity if velocity.y < 0 else FALL_GRAVITY

func dash_cooldown_timeout():
	canDash = true

func oil_slip():
	velocity.x *= .2

func pull_to_target(targetPosition: Vector2, delta: float):
	var directionBackToTarget = (targetPosition - global_position).normalized()
	velocity += directionBackToTarget * GRAPPLING_HOOK_SPEED * delta

	if global_position.distance_to(targetPosition) < GRAPPLING_HOOK_STOP_DISTANCE or rayCastLeft.is_colliding():
		MultiplayerManager.isBeingPulled = false

	move_and_slide()

func _draw() -> void:
	if isGrappling:
		draw_line(CENTER_OF_SPRITE, to_local(grappleToPosition), Color.BLACK, GRAPPLING_HOOK_WIDTH)
	if MultiplayerManager.drawGrapplingHook:
		draw_line(to_local(MultiplayerManager.grappleThrowerPosition), to_local(MultiplayerManager.grappleTargetPosition), Color.BLACK, GRAPPLING_HOOK_WIDTH)


func fire_grappling_hook():
	targetPlayer = get_leading_player()
	if targetPlayer:
		grappleToPosition = targetPlayer.global_position + CENTER_OF_SPRITE
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

	
