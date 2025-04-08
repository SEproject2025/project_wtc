extends Node

class Player:
	const SPEED = 200.0
	const DECELERATION = 0.1
	const ACCELERATION = 0.1
	const JUMP_VELOCITY = -350.0
	const WALL_JUMP_PUSHBACK = 360
	const WALL_SLIDE_GRAVITY = 100
	const DECELERATE_ON_JUMP_RELEASE = 0.8
	const FALL_GRAVITY = 1300.0
	const COYOTE_TIMER_LENGTH = 0.1
	const JUMP_BUFFER_TIME_LENGTH = 0.15
	const DASH_SPEED = 2.4
	const JUMP_DASHTIMER = 0.1
	const JETPACK_VELOCITY = -200
	const JETPACK_FUEL_CONSUMPTION = 25
	const GRAPPLING_HOOK_SPEED = 800.0
	const CENTER_OF_SPRITE = Vector2(3,-10) #Change if sprite changes
	const GRAPPLING_HOOK_WIDTH = 1.5
	const GRAPPLING_HOOK_STOP_DISTANCE = 10
	const OIL_SLIP_SPEED = 0.2
	const STUN_SPEED = 0.5
	const DASH_FUEL_CONSUMPTION = 25
	const BUMP_FORCE = Vector2(485, -100)
	const CAMERA_ZOOM_UPPER_ARBITRATOR = -132 #Compared to a camera's global position, which is tied to the player
	const CAMERA_ZOOM_LOWER_ARBITRATOR = -75
	const MIN_CAMERA_ZOOM = Vector2(1.4, 1.4)
	const MAX_CAMERA_ZOOM = Vector2(2.0, 2.0)
	const ZOOM_OUT_RATE = Vector2(0.01, 0.01)
	const ZOOM_IN_RATE = Vector2(0.006, 0.006)
class DeathWall:
	const WALL_TERMINAL_VELOCITY := 150.0
	const WALL_INITIAL_VELOCITY  := 70.0
	const WALL_ACCELERATION      := 0.002
	const WALL_MAX_DISTANCE      := 400
	const START_X := -270

enum PowerUpType {
	NONE,
	DASH,
	JETPACK,
	OILSPILL,
	GRAPPLINGHOOK,
}

const powerupIcons: Dictionary = {
	"DASH": preload("res://assets/powerups (placeholders)/dash_icon.png"),
	"JETPACK": preload("res://assets/powerups (placeholders)/jetpack_icon.png"),	
	"OILSPILL": preload("res://assets/powerups (placeholders)/oilspill_icon.png"),
	"GRAPPLINGHOOK": preload("res://assets/powerups (placeholders)/grapplinghook_icon.png"),
}

enum LobbyState { NOT_STARTED, STARTED }
