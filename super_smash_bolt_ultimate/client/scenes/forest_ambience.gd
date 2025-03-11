extends AudioStreamPlayer

var fading = false
var play_sound = false

func _ready() -> void:
	volume_db = -60
	
func _process(delta: float) -> void:
	if fading:
		volume_db += -120 * delta
		if volume_db <= -60:
			fading = false
	if play_sound:
		volume_db += 120 * delta
		if volume_db >= -10:
			play_sound = false
			
