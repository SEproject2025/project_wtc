extends ParallaxLayer

const CLOUD_SPEED = 10
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _process(delta: float) -> void:
	self.motion_offset.x += CLOUD_SPEED * delta
