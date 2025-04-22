extends Control

var pop_up_template = preload("res://scenes/pop_up.tscn")
var main_menu_template = preload("res://scenes/main_menu.tscn")
var in_lobby_menu_template = preload("res://scenes/in_lobby_menu.tscn")

# --- Node References ---
@onready var adjective1_dropdown = $Adjective1OptionButton
@onready var adjective2_dropdown = $Adjective2OptionButton
@onready var noun_dropdown = $NounOptionButton
# ---------------------

# --- Word lists for lobby names ---
const ADJECTIVES: Array[String] = [
	"Rusty", "Shiny", "Chrome", "Bleeping", "Whirring",
	"Clanking", "Automated", "Digital", "Circuit", "Gleaming"
]
const NOUNS: Array[String] = [
	"Bot", "Droid", "Gear", "Bolt", "Circuit",
	"Wire", "Piston", "Servo", "Sensor", "Cog"
]
# ---

func _init():
	User.client.lobby_list_received.connect(create_lobby_list)
	User.client.invalid_new_lobby_name.connect(invalid_new_lobby_name)
	User.client.invalid_join_lobby_name.connect(invalid_join_lobby_name)
	User.client.join_lobby.connect(_join_lobby)
	User.client.new_lobby.connect(_new_lobby)

# --- Populate dropdowns when the scene is ready ---
func _ready():
	# Clear any existing items (optional, good practice)
	adjective1_dropdown.clear()
	adjective2_dropdown.clear()
	noun_dropdown.clear()

	# Populate first adjective dropdown
	for i in range(ADJECTIVES.size()):
		adjective1_dropdown.add_item(ADJECTIVES[i], i) # Store index as ID

	# Populate second adjective dropdown
	for i in range(ADJECTIVES.size()):
		adjective2_dropdown.add_item(ADJECTIVES[i], i) # Store index as ID

	# Populate noun dropdown
	for i in range(NOUNS.size()):
		noun_dropdown.add_item(NOUNS[i], i) # Store index as ID

	# Optionally select the first item by default
	if adjective1_dropdown.item_count > 0:
		adjective1_dropdown.select(0)
	if adjective2_dropdown.item_count > 0:
		adjective2_dropdown.select(0)
	if noun_dropdown.item_count > 0:
		noun_dropdown.select(0)

	# Request lobby list on ready
	if User.client:
		User.client.request_lobby_list()
# ---

func invalid_join_lobby_name():
	var pop_up = pop_up_template.instantiate()
	pop_up.set_msg("   this lobby doesn't exist...\ntry refreshing",\
	 Color(255, 255, 255))
	pop_up.is_button_visible(false)
	add_child(pop_up)
	await get_tree().create_timer(1).timeout
	pop_up.queue_free()

func _join_lobby(lobby_info : String):
	var arr = lobby_info.split("***")
	var lobby_name = arr[0]
	var pop_up = pop_up_template.instantiate()
	pop_up.set_msg("   joining lobby...")
	pop_up.is_button_visible(false)
	add_child(pop_up)
	User.current_lobby_name = lobby_name
	User.current_lobby_state = arr[1].to_int() as Constants.LobbyState
	print("joined lobby %s !" %lobby_name)
	get_parent().add_child(in_lobby_menu_template.instantiate())
	queue_free()

func _new_lobby(lobby_name : String):
	var pop_up = pop_up_template.instantiate()
	pop_up.set_msg("   creating a new lobby...")
	pop_up.is_button_visible(false)
	add_child(pop_up)
	User.is_host = true
	User.current_lobby_name = lobby_name
	print("new lobby created %s !" %lobby_name)
	get_parent().add_child(in_lobby_menu_template.instantiate())
	queue_free()

func invalid_new_lobby_name():
		var pop_up = pop_up_template.instantiate()
		pop_up.set_msg("lobby name taken!")
		add_child(pop_up)

func create_lobby_list(lobby_list : PackedStringArray):
	if lobby_list.is_empty():
		var pop_up = pop_up_template.instantiate()
		pop_up.set_msg("no lobby exists :(\ncreate one!")
		add_child(pop_up)
	
	
	var container = $VBoxContainer/ScrollContainer/VBoxContainer
	for i in container.get_children():
		if i != null:
			i.queue_free()
	for i in lobby_list:
		var lobby_list_label = $Lobby_template.duplicate()
		lobby_list_label.show()
		lobby_list_label.get_child(0).text = i
		lobby_list_label.get_child(1).pressed.connect(_on_join_lobby_pressed.bind(lobby_list_label.get_child(0).text))
		container.add_child(lobby_list_label)

func _on_join_lobby_pressed(_lobby_name : String):
	User.client.request_join_lobby(_lobby_name)

# --- Create lobby using dropdown selections ---
func _on_new_lobby_pressed():
	var adj1_id = adjective1_dropdown.get_selected_id()
	var adj2_id = adjective2_dropdown.get_selected_id()
	var noun_id = noun_dropdown.get_selected_id()

	# Check if an item is selected in each dropdown
	if adj1_id == -1 or adj2_id == -1 or noun_id == -1:
		var pop_up = pop_up_template.instantiate()
		pop_up.set_msg("Please select an option\nfrom all three dropdowns!")
		add_child(pop_up)
		return # Stop processing if any dropdown is not selected

	# Get the text from the selected items
	var adj1_text = adjective1_dropdown.get_item_text(adj1_id)
	var adj2_text = adjective2_dropdown.get_item_text(adj2_id)
	var noun_text = noun_dropdown.get_item_text(noun_id)

	# Combine the selected words into the lobby name (e.g., "Shiny Whirring Bot")
	var lobby_name : String = "%s%s%s" % [adj1_text, adj2_text, noun_text]

	# Optional: Prevent selecting the same adjective twice?
	# if adj1_id == adj2_id:
		# var pop_up = pop_up_template.instantiate()
		# pop_up.set_msg("Please select two\ndifferent adjectives!")
		# add_child(pop_up)
		# return

	print("Requesting new lobby: ", lobby_name) # Debug print
	User.client.request_new_lobby(lobby_name)
# ---

func _on_return_pressed():
	get_parent().add_child(load("res://scenes/main_menu.tscn").instantiate())
	User.reset_connection()
	queue_free()

func _on_refresh_pressed():
	User.client.request_lobby_list()


func _on_lobby_name_text_submitted(new_text):
	_on_new_lobby_pressed()
