##
extends CharacterBody2D

const PLAYER = Constants.Player

var fall_rate = PLAYER.DECELERATE_ON_JUMP_RELEASE
var bumped: bool = false
var coyoteJump: bool = true
var isDashing: bool = false
var canDash: bool = true
var jumpBuffered: bool = false
var wallJumping: bool = false
var jumpReleased: bool = false
var _is_on_floor: bool = true
var isStunned: bool = false
var alive: bool = true
var pullTargetPosition: Vector2
var isGrappling: bool = false
var isBeingGrappled: bool = false
var isSlipping: bool = false
var lost_pop_up_template = preload("res://scenes/end_pop_up.tscn")

@onready var animated_sprite: Sprite2D = $Sprite2D
@onready var coyoteTimer: Timer = $Timers/CoyoteTimer
@onready var dashTimer: Timer = $Timers/DashTimer
@onready var jumpBufferTimer: Timer = $Timers/JumpBufferTimer
@onready var dashCooldown: Timer = $"Timers/DashCooldown"
@onready var powerupManager = $PowerUpManager
@onready var rayCastRight: RayCast2D = $RayCasts/RayCastRight
@onready var rayCastLeft: RayCast2D = $RayCasts/RayCastLeft
@onready var raycastToObstacle: RayCast2D = $RayCasts/RayCastToObstacle
@onready var rayCastRightToPlayer: RayCast2D = $RayCasts/RayCastRightToPlayer
@onready var rayCastLeftToPlayer: RayCast2D = $RayCasts/RayCastLeftToPlayer
@onready var dashEffectTimer: Timer = $Timers/DashEffectTimer
@onready var oilSpillTimer: Timer = $Timers/OilSpillTimer
@onready var stunTimer:Timer = $Timers/StunTimer

var hostSprite = preload("res://assets/sprites/character_sprites/blue_bot_mothersheet.png")

@export var player_input: PlayerInput
@export var player_id := 1:
	set(id):
		player_id = id



var attack_state : bool = false
var attack_count : int = 1
var attack_timer : int = 0
@onready var health = $Control/VBoxContainer/Control/TextureProgressBar
@onready var original_anim_tree = $AnimationTree
@onready var anim_tree = $AnimationTree.get("parameters/playback")
@onready var anim_player = $AnimationPlayer
@onready var character_name = $Control/VBoxContainer/Control2/Label
@onready var player_spawn_x = position.x
@onready var player_spawn_y = position.y

func _ready():
	reset()

func _process(_delta):
#	check_health()
	set_animation()
	if Input.is_action_just_pressed("use_powerup") and !powerupManager.is_jetpack_active and !powerupManager.is_dash_powerup_active:
		powerupManager.use_powerup()
	if Input.is_action_just_pressed("reset"):
		reset()

func _physics_process(delta):
	apply_movement(delta)

func reset():
	#set_physics_process(false)
	#set_process(false)
	#set_process_input(false)
	position.x = player_spawn_x
	position.y = player_spawn_y
	#await get_tree().create_timer(5).timeout

	$AnimationTree.set_active(true)
	health.value = 100
#	if get_multiplayer_authority() == (User.ID):
	$AnimationTree.set_active(true)
	$Camera2D.enabled = true
	character_name.text = "Doug"
	set_physics_process(true)
	set_process_input(true)
	set_process(true)
#		set_player_name.rpc(User.user_name)	
#		if User.is_host:
#			set_sprite.rpc()
	#else:
		#character_name.text = "Other player"
		#set_physics_process(false)
		#set_process(false)
		#set_process_input(false)

#func check_health():
#	if health.value <= 0:
#		die.rpc()

func set_animation():
	if Input.is_action_just_pressed("jump") :
		anim_tree.travel("jump")
#		sync_animation.rpc("jump")
	elif Input.is_action_just_pressed("left_mouse"):
		attack_state = true
		attack_timer = Time.get_ticks_msec()
	elif Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right"):
		if is_on_floor() and not attack_state:
			anim_tree.travel("run")
#			sync_animation.rpc("run")
	elif is_on_floor() and not attack_state:
		anim_tree.travel("idle")
#		sync_animation.rpc("idle")

	if attack_state:
		if Time.get_ticks_msec() - attack_timer >= 600:
			attack_state = false
			attack_count = 1

func _on_area_2d_body_entered(body):
	if body != self:
		body.hit_received.rpc()

func apply_movement(delta: float):
	if isStunned:
		handle_stunned_movement(delta)
		return

	if isBeingGrappled:
		handle_being_grappled_movement(delta)
		return

	var direction = Input.get_axis("move_left", "move_right")

	if not is_on_floor():
		if coyoteJump and coyoteTimer.is_stopped():
			coyoteTimer.start(PLAYER.COYOTE_TIMER_LENGTH)
		if not isDashing or not (Input.is_action_just_pressed("use_powerup") and powerupManager.is_dash_powerup_active):
			velocity.y += return_gravity() * delta
		if not is_on_wall_only():
			anim_tree.travel("fall_start")
#			sync_animation.rpc("fall_start")
	else:
		coyoteJump = true
		coyoteTimer.stop()

	if powerupManager.is_jetpack_active:
		if Input.is_action_pressed("use_powerup") and powerupManager.jetpack_fuel > 0:
			velocity.y = PLAYER.JETPACK_VELOCITY
			powerupManager.jetpack_fuel -= PLAYER.JETPACK_FUEL_CONSUMPTION * delta
		if powerupManager.jetpack_fuel <= 0:
			powerupManager.deactivate_jetpack()

	if powerupManager.is_dash_powerup_active:
		if Input.is_action_pressed("use_powerup") and powerupManager.dashFuel > 0:
			var collidingRayCast = rayCastRightToPlayer if rayCastRightToPlayer.is_colliding() else rayCastLeftToPlayer if rayCastLeftToPlayer.is_colliding() else null
			if collidingRayCast:
				var collider = collidingRayCast.get_collider()
				if collider and not collider.isStunned:
					collider.get_stunned.rpc()
			handle_dash_movement(direction)
			powerupManager.dashFuel -= PLAYER.DASH_FUEL_CONSUMPTION * delta
		if powerupManager.dashFuel <= 0:
			powerupManager.deactivate_dash()

	if Input.is_action_just_pressed("jump"):
		jump()

	# Variable Jump Height
	if !Input.is_action_pressed("jump") and velocity.y < 0:
		velocity.y *= fall_rate

	if is_on_wall_only() and Input.get_axis("move_left", "move_right"):
		wall_slide()

	if isSlipping:
		handle_oilspill_movement(direction)
	elif isDashing:
		handle_dash_movement(direction)
		var collidingRayCast = rayCastRightToPlayer if rayCastRightToPlayer.is_colliding() else rayCastLeftToPlayer if rayCastLeftToPlayer.is_colliding() else null
		if collidingRayCast:
			var collider = collidingRayCast.get_collider()
			if collider == CharacterBody2D:
				collider.get_bumped.rpc(direction)
	elif powerupManager.isGrappling:
		handle_grappling_movement(delta)
	elif direction:
		velocity.x = move_toward(velocity.x, direction * PLAYER.SPEED, PLAYER.SPEED * PLAYER.ACCELERATION)
		animated_sprite.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, PLAYER.SPEED * PLAYER.DECELERATION)

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
	animated_sprite.flip_h = true
	anim_tree.travel("jump")
#	sync_animation.rpc("jump")

func wall_slide():
	velocity.y = min(velocity.y, PLAYER.WALL_SLIDE_GRAVITY)
	anim_tree.travel("wall_slide")
#	sync_animation.rpc("wall_slide")

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
		fall_rate = PLAYER.DECELERATE_ON_JUMP_RELEASE
	return gravity

#region Horizontal Movement
func handle_grappling_movement(delta: float):
	var directionToTarget = (powerupManager.grappleTargetPosition - global_position).normalized()
	velocity += directionToTarget * PLAYER.GRAPPLING_HOOK_SPEED * delta

func handle_oilspill_movement(direction: float):
	if isDashing or abs(velocity.x) > PLAYER.SPEED:
		velocity.x = lerp(velocity.x, velocity.x * PLAYER.OIL_SLIP_SPEED, PLAYER.OIL_SLIP_SPEED)
	else:
		velocity.x = move_toward(velocity.x, direction * PLAYER.SPEED * PLAYER.OIL_SLIP_SPEED, PLAYER.SPEED * PLAYER.ACCELERATION * PLAYER.OIL_SLIP_SPEED)

func handle_dash_movement(direction: int) :
	if not direction:
		var dashDirection = -1 if animated_sprite.flip_h else 1
		velocity.x = move_toward(velocity.x, dashDirection * PLAYER.SPEED * PLAYER.DASH_SPEED, PLAYER.SPEED * PLAYER.ACCELERATION * PLAYER.DASH_SPEED)
	else:
		velocity.x = move_toward(velocity.x, direction * PLAYER.SPEED * PLAYER.DASH_SPEED, PLAYER.SPEED * PLAYER.ACCELERATION * PLAYER.DASH_SPEED)

func handle_being_grappled_movement(delta: float):
	var directionBackToTarget = (pullTargetPosition - global_position).normalized()
	velocity += directionBackToTarget * PLAYER.GRAPPLING_HOOK_SPEED * delta

	if global_position.distance_to(pullTargetPosition) < PLAYER.GRAPPLING_HOOK_STOP_DISTANCE or rayCastLeft.is_colliding():
		isBeingGrappled = false
	move_and_slide()

func handle_stunned_movement(delta: float):
	var direction = Input.get_axis("move_left", "move_right")
	animated_sprite.flip_h = direction < 0;
	if velocity.y > 0 and !is_on_floor():
		velocity.y += return_gravity() * delta
	velocity.x = move_toward(velocity.x, direction * PLAYER.SPEED * PLAYER.STUN_SPEED, PLAYER.SPEED * PLAYER.ACCELERATION * PLAYER.STUN_SPEED)
	move_and_slide()

#endregion

#region Timers
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

func oil_spill_timer_timeout():
	isSlipping = false

func _on_dash_effect_timer_timeout():
	var playerCopy = animated_sprite.duplicate()
	get_tree().get_root().add_child(playerCopy)
	playerCopy.global_position = global_position + 3 * PLAYER.CENTER_OF_SPRITE

	var effectTime = dashTimer.wait_time / 3
	await get_tree().create_timer(effectTime).timeout
	playerCopy.modulate.a = 0.4

	await get_tree().create_timer(effectTime).timeout
	playerCopy.modulate.a = 0.2

	await get_tree().create_timer(effectTime).timeout
	playerCopy.queue_free()

func stun_timer_timeout():
	isStunned = false
	set_physics_process(true)
	set_process(true)
#endregion

#region RPCs
	pass
@rpc("any_peer","call_remote","reliable")
func set_player_name(_name : String):
	character_name.text = "Doug"

@rpc("any_peer","call_local","reliable")
func set_sprite():
	animated_sprite.texture = hostSprite

@rpc("any_peer","call_local","reliable")
func die(player_name: int):
	$AnimationTree.set_active(false)
	anim_player.play("dead")
	set_player_name("press R to Reset")
	set_physics_process(false)
	#set_process(false)
	#if get_multiplayer_authority() == (User.ID):
		#var lost_pop_up = lost_pop_up_template.instantiate()
		#add_child(lost_pop_up)
	character_name.text = "press R to Reset"

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

@rpc("any_peer")
func begin_pulling_to_target(pullPosition: Vector2):
	isBeingGrappled = true
	pullTargetPosition = pullPosition + PLAYER.CENTER_OF_SPRITE

@rpc("any_peer", "call_remote", "reliable")
func get_stunned():
	isStunned = true
	stunTimer.start(2)

@rpc("any_peer", "call_remote", "reliable")
func get_bumped(direction: int):
	velocity += Vector2(direction * PLAYER.BUMP_FORCE.x, PLAYER.BUMP_FORCE.y)
#endregion
