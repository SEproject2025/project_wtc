extends CharacterBody2D

const SPEED = 100.0
const JUMP_VELOCITY = -300.0

@onready var animated_sprite = $AnimatedSprite2D

# Syncs the project settings' gravity with the RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var _is_on_floor = true
var alive = true

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

func _apply_animations(delta):
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
		velocity.y += gravity * delta
	elif player_input.input_jump > 0:
		# player jump
		velocity.y = JUMP_VELOCITY * player_input.input_jump

	# the input direction, -1, 0, 1
	var direction = player_input.input_direction
	
	# player movement
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

func _physics_process(delta):
	if is_multiplayer_authority():
		if not alive && is_on_floor():
			_set_alive()
		
		_is_on_floor = is_on_floor()
		_apply_movement_from_input(delta)

func _process(delta):
	if not multiplayer.is_server() || MultiplayerManager.host_mode_enabled:
		_apply_animations(delta)

func set_dead():
	alive = false
	$CollisionShape2D.set_deferred("disabled", true)
	$RespawnTimer.start()

func _respawn():
	position = MultiplayerManager.respawn_point
	$CollisionShape2D.set_deferred("disabled", false)

func _set_alive():
	alive = true
	Engine.time_scale = 1.0
