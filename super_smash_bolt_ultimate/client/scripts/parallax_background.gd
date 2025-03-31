extends ParallaxBackground

@onready var animation_player = $AnimationPlayer


func _ready():
	pass

func cavetoforest():
	animation_player.play("Scene transition")
	print("cavetoforest!")
func foresttocave():
	animation_player.play("foresttocave")
	print("foresttocave!")
