extends CanvasLayer
var fuel
var power_fuel

# Called when the node enters the scene tree for the first time.
func _ready():
	fuel = get_node("boost_fuel")
	power_fuel = get_node("power_fuel")
	pass 

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if power_fuel.value > 0:
		$ui_base_extension.set_visible(true)
		$powerup_battery.set_visible(true)
	else:
		$ui_base_extension.set_visible(false)
		$powerup_battery.set_visible(false)
	#pass
