extends Node2D

var yellow_bot_sprite    = preload("res://assets/sprites/character_sprites/mine_bot_mothersheet_complete.png")
var red_bot_sprite       = preload("res://assets/sprites/character_sprites/red_bot_mothersheet.png")
var blue_bot_sprite      = preload("res://assets/sprites/character_sprites/blue_bot_mothersheet.png")
var orange_bot_sprite    = preload("res://assets/sprites/character_sprites/orange_bot_mothersheet.png")
var purple_bot_sprite    = preload("res://assets/sprites/character_sprites/purple_guy_mothersheet.png")
var green_bot_sprite     = preload("res://assets/sprites/character_sprites/lime_bot_mothersheet_2.png")
var pink_bot_sprite      = preload("res://assets/sprites/character_sprites/pink_bot_mothersheet.png")
var zorro_bot_sprite     = preload("res://assets/sprites/character_sprites/zorrobot_mothersheet.png")
var vermilion_bot_sprite = preload("res://assets/sprites/character_sprites/vermilion_bot_mothersheet.png")
@onready var animated_sprite = $Sprite2D

func set_color(bot_color):
	match bot_color:
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
