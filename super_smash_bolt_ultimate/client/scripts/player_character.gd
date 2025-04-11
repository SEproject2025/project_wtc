##
extends CharacterBody2D

const PLAYER = Constants.Player

signal displacement_updated(player_id, displacement)

var fall_rate = PLAYER.DECELERATE_ON_JUMP_RELEASE
var bumped: bool = false
var coyoteJump: bool = true
var isDashing: bool = false
var canDash: bool = true
var jumpBuffered: bool = false
var wallJumping: bool = false
var jumpReleased: bool = false
var _is_on_floor: bool = true
var isPowerUpDashing: bool  = false
var isStunned: bool = false
var alive: bool = true
var pullTargetPosition: Vector2
var isGrappling: bool = false
var isBeingGrappled: bool = false
var isSlipping: bool = false
var displacement := 0.0
var maxDisplacement := 0.0
var prev_x := global_position.x
var lost_pop_up_template = preload("res://scenes/end_pop_up.tscn")
var ui_template = preload("res://scenes/UI.tscn")
var ui
var lasySyncedDisplacement := 0.0
var spectator: bool = false
var stay_zoomed_out = true

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
@onready var hitFlashAnimationPlayer = $HitFlashAnimationPlayer
@onready var displacement_hud = $Label
@onready var displacementUpdateTimer: Timer = $Timers/DisplacementUpdateTimer
@onready var death_explosion = preload("res://scenes/death_explosion.tscn")
@onready var zoom_timer: Timer = $Timers/ZoomTimer

var yellow_bot_sprite    = preload("res://assets/sprites/character_sprites/mine_bot_mothersheet_complete.png")
var red_bot_sprite       = preload("res://assets/sprites/character_sprites/red_bot_mothersheet.png")
var blue_bot_sprite      = preload("res://assets/sprites/character_sprites/blue_bot_mothersheet.png")
var orange_bot_sprite    = preload("res://assets/sprites/character_sprites/orange_bot_mothersheet.png")
var purple_bot_sprite    = preload("res://assets/sprites/character_sprites/purple_guy_mothersheet.png")
var green_bot_sprite     = preload("res://assets/sprites/character_sprites/lime_bot_mothersheet_2.png")
var pink_bot_sprite      = preload("res://assets/sprites/character_sprites/pink_bot_mothersheet.png")
var zorro_bot_sprite     = preload("res://assets/sprites/character_sprites/zorrobot_mothersheet.png")
var vermilion_bot_sprite = preload("res://assets/sprites/character_sprites/vermilion_bot_mothersheet.png")

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

func _ready():
	User.client.other_user_joined_game.connect(_other_user_joined_game)
	player_id = randi_range(1,7)
	if User.user_name.to_upper() == "ZORRO":
		player_id = 8
	
	if spectator:
			set_process(false)
			set_physics_process(false)
			await get_tree().create_timer(.01).timeout
			set_invisible.rpc()
			_set_rpc_visiblity_off.rpc()
			$Camera2D.enabled = false
			position = get_tree().get_nodes_in_group("Players")[0].position
			get_parent().get_node("EndPopUp")._on_spectate_pressed()
			return
	reset()
	

func _process(_delta):
	check_health()
	set_animation()
	set_zoom()
	if Input.is_action_just_pressed("use_powerup") and !powerupManager.is_jetpack_active and !powerupManager.is_dash_powerup_active:
		powerupManager.use_powerup()
	if ui.fuel.value != ui.fuel.max_value:
		ui.fuel.value = ui.fuel.max_value - (dashCooldown.time_left * 10)
	if powerupManager.is_jetpack_active or powerupManager.is_dash_powerup_active:
		ui.power_fuel.value = powerupManager.fuel

func _physics_process(delta):
	apply_movement(delta)

func reset():
	set_physics_process(false)
	set_process(false)
	set_process_input(false)

	$AnimationTree.set_active(true)
	health.value = 100

	await get_tree().create_timer(.01).timeout
	var is_authority: bool = get_multiplayer_authority() == User.ID

	if is_authority:
		$Camera2D.enabled = true
		$Camera2D.make_current()
		$Label.show()
		character_name.text = User.user_name
		
		ui = ui_template.instantiate()
		get_tree().get_root().get_node("game_scene").add_child(ui)
		ui.fuel.set_max(dashCooldown.get_wait_time() * 10)
	else:
		$Label.hide()
		displacement_hud.text = ""
		character_name.text = "Other player" if character_name.text == 'Player Name' else character_name.text

	if !User.is_spectator:
		await get_tree().create_timer(5.0).timeout
		set_physics_process(is_authority)
		set_process_input(is_authority)
		set_process(is_authority)


func check_health():
	if health.value <= 0:
		die.rpc(self.name.to_int())

func set_zoom():
	if $Camera2D.global_position.y < PLAYER.CAMERA_ZOOM_ARBITRATOR and $Camera2D.zoom > PLAYER.MIN_CAMERA_ZOOM:
		$Camera2D.zoom -= PLAYER.ZOOM_OUT_RATE
		#stay_zoomed_out = true #This feature is not ready to be published. It needs more polish.
		#zoom_timer.start()
	elif  $Camera2D.global_position.y > PLAYER.CAMERA_ZOOM_ARBITRATOR and $Camera2D.zoom < PLAYER.MAX_CAMERA_ZOOM: #and !stay_zoomed_out
		$Camera2D.zoom += PLAYER.ZOOM_IN_RATE
		

func set_animation():
	if isDashing:
		anim_tree.travel("dash")
		sync_animation.rpc("dash")
	elif Input.is_action_just_pressed("jump"):
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

func _on_area_2d_body_entered(body):
	if body != self:
		body.hit_received.rpc()

func apply_movement(delta: float):
	prev_x = global_position.x
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
		if (not isDashing) and (not (Input.is_action_just_pressed("use_powerup") and powerupManager.is_dash_powerup_active)):
			velocity.y += return_gravity() * delta
		if not is_on_wall_only():
			anim_tree.travel("fall_start")
			sync_animation.rpc("fall_start")
	else:
		coyoteJump = true
		coyoteTimer.stop()

	if powerupManager.is_jetpack_active:
		if Input.is_action_pressed("use_powerup") and powerupManager.is_jetpack_active:
			velocity.y = PLAYER.JETPACK_VELOCITY
			powerupManager.fuel -= PLAYER.JETPACK_FUEL_CONSUMPTION * delta
		if powerupManager.fuel <= 0:
			powerupManager.deactivate_jetpack()

	if powerupManager.is_dash_powerup_active:
		if Input.is_action_pressed("use_powerup"):
			isPowerUpDashing = true
			var collidingRayCast = rayCastRightToPlayer if rayCastRightToPlayer.is_colliding() else rayCastLeftToPlayer if rayCastLeftToPlayer.is_colliding() else null
			if collidingRayCast:
				var collider = collidingRayCast.get_collider()
				if  collider and collider.get_script() == $".".get_script() and not collider.isStunned:
					collider.get_stunned.rpc()
			handle_dash_movement(direction)
			powerupManager.fuel -= PLAYER.DASH_FUEL_CONSUMPTION * delta
		else:
			isPowerUpDashing = false
		if powerupManager.fuel <= 0:
			powerupManager.deactivate_dash()

	if Input.is_action_just_pressed("jump"):
		jump()

	# Variable Jump Height
	if !Input.is_action_pressed("jump") and velocity.y < 0:
		velocity.y *= fall_rate

	if !is_on_floor() and (rayCastRight.is_colliding() or rayCastLeft.is_colliding()):
		wall_slide()

	if isSlipping:
		handle_oilspill_movement(direction)
	elif isDashing:
		handle_dash_movement(direction)
		var collidingRayCast = rayCastRightToPlayer if rayCastRightToPlayer.is_colliding() else rayCastLeftToPlayer if rayCastLeftToPlayer.is_colliding() else null
		if collidingRayCast:
			var collider = collidingRayCast.get_collider()
			if collider and collider.get_script() == $".".get_script():
				if direction:
					collider.get_bumped.rpc(direction)
				else:
					collider.get_bumped.rpc(-1 if animated_sprite.flip_h else 1)
	elif powerupManager.isGrappling:
		handle_grappling_movement(delta)
	elif direction:
		velocity.x = move_toward(velocity.x, direction * PLAYER.SPEED, PLAYER.SPEED * PLAYER.ACCELERATION)
		if (is_on_floor() or (!rayCastRight.is_colliding() and !rayCastLeft.is_colliding())): #if not wall sliding
			animated_sprite.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, PLAYER.SPEED * PLAYER.DECELERATION)

	if Input.is_action_just_pressed("dash") and canDash:
		if !isDashing:
			start_dash()

	var wasOnFloor = is_on_floor()
	move_and_slide()
	displacement += global_position.x - prev_x
	displacement_hud.text = "%.1f m" % displacement
	maxDisplacement = max(displacement, maxDisplacement)

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

	if !is_on_floor() and (rayCastRight.is_colliding() or rayCastLeft.is_colliding()):
		wall_jump()

func wall_jump():
	var wall_jump_direction = 1
	if rayCastRight.is_colliding():
		wall_jump_direction = -1
	velocity = Vector2(wall_jump_direction * PLAYER.WALL_JUMP_PUSHBACK, PLAYER.JUMP_VELOCITY)
	animated_sprite.flip_h = true
	anim_tree.travel("jump")
	sync_animation.rpc("jump")

func wall_slide():
	if !is_on_wall_only():
		if rayCastRight.is_colliding():
			position.x += PLAYER.WALL_MAGNETISM
			animated_sprite.flip_h = false
		else:
			position.x -= PLAYER.WALL_MAGNETISM
			animated_sprite.flip_h = true
	velocity.y = min(velocity.y, PLAYER.WALL_SLIDE_GRAVITY)
	anim_tree.travel("wall_slide")
	sync_animation.rpc("wall_slide")

func start_dash():
	isDashing = true
	canDash = false
	ui.fuel.value = 0
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
func die_explode():
	var begin_death = death_explosion.instantiate()
	add_child(begin_death)
	begin_death.set_sprite(animated_sprite.texture)
	begin_death.set_momentum(velocity)
	
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
	animated_sprite.flip_h = direction < 0
	if not is_on_floor():
		velocity.y += return_gravity() * delta
	velocity.x = move_toward(velocity.x, direction * PLAYER.SPEED * PLAYER.STUN_SPEED, PLAYER.SPEED * PLAYER.ACCELERATION * PLAYER.STUN_SPEED)
	move_and_slide()

#endregion

#region Timers
func zoom_timer_timeout():
	stay_zoomed_out = false
	zoom_timer.stop()

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
	playerCopy.global_position = global_position + PLAYER.CENTER_OF_SPRITE * 3

	var effectTime = dashTimer.wait_time / 3
	await get_tree().create_timer(effectTime).timeout
	playerCopy.modulate.a = 0.4

	await get_tree().create_timer(effectTime).timeout
	playerCopy.modulate.a = 0.2

	await get_tree().create_timer(effectTime).timeout
	playerCopy.queue_free()

func stun_timer_timeout():
	isStunned = false

func on_displacement_update_timer():
	if maxDisplacement > lasySyncedDisplacement:
		lasySyncedDisplacement = maxDisplacement
		sync_displacement.rpc()

#endregion

#region RPCs
@rpc("any_peer","call_remote","reliable")
func set_player_name(_name : String):
	print("Here is the name: %s" % _name)
	character_name.text = _name

@rpc("any_peer","call_local","reliable")
func set_sprite(player_id):
	match player_id:
		1:
			animated_sprite.texture = yellow_bot_sprite
		2:
			animated_sprite.texture = orange_bot_sprite
		3:
			animated_sprite.texture = red_bot_sprite
		4:
			animated_sprite.texture = purple_bot_sprite
		5:
			animated_sprite.texture = blue_bot_sprite
		6:
			animated_sprite.texture = green_bot_sprite
		7:
			animated_sprite.texture = pink_bot_sprite
		8:
			animated_sprite.texture = zorro_bot_sprite
		_:
			animated_sprite.texture = vermilion_bot_sprite

@rpc("any_peer","call_local","reliable")
func die(player_name: int):
	print("Player %d died" %player_name)
	#$AnimationTree.set_active(false)
	#anim_player.play("dead")
	call_deferred("die_explode")
	set_physics_process(false)
	set_process(false)
	alive = false
	$Sprite2D.visible = false
	$Label.visible = false
	$Control.visible = false
	await get_tree().create_timer(0.5).timeout
	if get_tree().get_nodes_in_group("Players").filter(func(player): return player.alive).size() > 0:
		$Camera2D.enabled = false
	if get_multiplayer_authority() == (User.ID):
		ui.set_visible(false)
		$PowerUpUI.visible = false
		get_tree().get_root().get_node("game_scene").enable_death_pop_up()
	User.client.player_died.emit(player_name)
		

	# reset()

@rpc ("any_peer","call_local","reliable")
func sync_displacement():
	displacement_updated.emit(self.name, maxDisplacement)

@rpc("any_peer","call_remote","reliable")
func sync_animation(anim_name: StringName):
	anim_tree.travel(anim_name)

@rpc("any_peer","call_remote","reliable")
func sync_flip(dir : int):
	$Area2D.transform.x.x = dir

@rpc("any_peer","call_local","reliable")
func hit_received():
	# anim_tree.start("Hurt", true)
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

	velocity.x = clamp(velocity.x, -PLAYER.BUMP_FORCE.x, PLAYER.BUMP_FORCE.x)
	velocity.y = clamp(velocity.y, -PLAYER.BUMP_FORCE.x, PLAYER.BUMP_FORCE.y)
#endregion

func format_displacement(value: float) -> String:
	return "Displacement: %.2fm" % value

@rpc("any_peer", "call_local", "reliable")
func set_invisible():
	visible = false
	alive = false
	$CollisionShape2D.disabled = true
	spectator = true
	
func _other_user_joined_game(_id: int):
	if get_multiplayer_authority() == User.ID:
		await get_tree().create_timer(.01).timeout
		set_sprite.rpc(player_id)
		set_player_name.rpc(User.user_name)

@rpc("any_peer", "call_local", "reliable")
func _set_rpc_visiblity_off():
	$MultiplayerSynchronizer.public_visibility = false
	$Input/InputSynchronizer.public_visibility = false
	$PlayerSynchronizer.public_visibility = false
