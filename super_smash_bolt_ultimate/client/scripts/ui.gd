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
	if power_fuel.value > 0 and fuel.visible:
		fuel.set_visible(false)
	if power_fuel.value == 0 and !fuel.visible:
		fuel.set_visible(true)
	pass
