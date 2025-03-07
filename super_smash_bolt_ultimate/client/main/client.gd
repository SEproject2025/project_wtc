extends Node
class_name Client

# Enum representing the types of messages exchanged between client and server
enum Message {USER_INFO, LOBBY_LIST , NEW_LOBBY, JOIN_LOBBY, LEFT_LOBBY, LOBBY_MESSAGE, \
START_GAME, OFFER, ANSWER, ICE, GAME_STARTING, HOST, MAP_SEED, LEFT_GAME, SPAWN_POSITIONS, AI_SEED}

var rtc_mp = WebRTCMultiplayerPeer.new()
var ws = WebSocketPeer.new()
# var url = "127.0.0.1:9999"
var url = "wss://godot.silfsy.com"
var client_connected : bool = false
var ai_seed: int = 0

# Signals for various events
signal invalid_new_lobby_name
signal invalid_user_name
signal invalid_join_lobby_name
signal join_lobby(lobby_name : String)
signal new_lobby(lobby_name : String)
signal lobby_list_received(lobby_list : PackedStringArray)
signal lobby_messsage_received(message : String, user_name : String)
signal other_user_joined_lobby(user_name : String)
signal host_name_received(host_name : String)
signal some_one_left_lobby(player_name : String)
signal offer_received(type: String, sdp: String)
signal answer_received(type: String, sdp: String)
signal ice_received(media: String, index: int, _name: String)
signal game_start_received(arr : String)
signal server_changed_host()
signal user_name_feedback_received
signal reset_connection
signal map_seed_received(seed: int)
signal some_one_left_game(id : int)
signal spawn_positions_received(spawn_positions : Dictionary)
signal player_died(id : int)

# Attempt to connect to the WebSocket server
func _init():
	var error = ws.connect_to_url(url)
	if error != OK:
		print ("ERROR: Can not connect to url!")

# Check if the WebSocket connection is open and can send a test message
func is_connection_valid() -> bool:
	if ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		var error = ws.send_text("Test msg!")
		if error == OK:
			print("Connection seems OK! (But no server feedback at this point!)")
			return true
		else:
			print("ERROR: Connection failed!")
	
	return false

# Poll WebSocket for events and process messages or handle disconnection
func _process(delta):
	ws.poll()
	var state = ws.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		while ws.get_available_packet_count():
			parse_msg()
	# Keep polling to ensure a proper close
	elif state == WebSocketPeer.STATE_CLOSING:
		pass
	elif state == WebSocketPeer.STATE_CLOSED:
		var code = ws.get_close_code()
		var reason = ws.get_close_reason()
		print("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
		# Stop further processing
		set_process(false)
		client_connected = false
		reset_connection.emit()

# parse incoming WebSocket message
func parse_msg():
	var parsed = JSON.parse_string(ws.get_packet().get_string_from_utf8())
	
	# Validate that the message has necessary fields
	if not typeof(parsed) == TYPE_DICTIONARY \
	or not parsed.has("type") \
	or not parsed.has("id") \
	or not parsed.has("data"):
		return false
	
	var msg = {
		"type": str(parsed.type).to_int(),
		"id": str(parsed.id).to_int(),
		"data": parsed.data
	}
	
	# Ensure message type and id are valid integers
	if not str(msg.type).is_valid_int() \
	or not str(msg.id).is_valid_int():
		return false
	
	var type := str(msg.type).to_int()
	var id := str(msg.id).to_int()
	var data : String = str(msg.data)
	
	# Handle different message types
	if type == Message.USER_INFO:
		if data == "INVALID":
			invalid_user_name.emit()
			return
		User.user_name = data
		User.ID = id
		print("Received User name = %s ID# %s" %[data, id])
		user_name_feedback_received.emit()
		client_connected = true
		return
	
	if type == Message.HOST:
		if id == User.ID and data == User.user_name:
			User.is_host = true
		else:
			User.is_host = false
			User.host_name = data
		server_changed_host.emit()
		return
	
	if type == Message.ICE:
		var str_arr = data.split("***", true , 3)
		var media : String = str_arr[0]
		var index : int = int(str_arr[1])
		var _name : String = str_arr[2]
		var sender_id = id
		ice_received.emit(media, index, _name, sender_id)
		return
	
	if type == Message.ANSWER:
		var str_arr = data.split("***", true , 2)
		var _type : String = str_arr[0]
		var sdp : String = str_arr[1]
		var sender_id = id
		answer_received.emit(_type, sdp, sender_id)
		return
	
	if type == Message.OFFER:
		var str_arr = data.split("***", true , 2)
		var _type : String = str_arr[0]
		var sdp : String = str_arr[1]
		var sender_id = id
		offer_received.emit(_type, sdp, sender_id)
		return
	
	if type == Message.NEW_LOBBY:
		if data == "INVALID":
			invalid_new_lobby_name.emit()
			return
		else:
			new_lobby.emit(data)
			return
	
	if type == Message.JOIN_LOBBY:
		if data.contains("INVALID"):
			invalid_join_lobby_name.emit()
			return
		if data.contains("LOBBY_NAME"):
			join_lobby.emit(data.right(-10))
			return
		if data.contains("NEW_JOINED_USER_NAME"):
			User.peers[id] = data.right(-20)
			other_user_joined_lobby.emit(data.right(-20))
			print("Peer name: %s with ID # %s added to the list." %[data.right(-20), id])
			return
		if data.contains("EXISTING_USER_NAME"):
			User.peers[id] = data.right(-18)
			other_user_joined_lobby.emit(data.right(-18))
			print("Peer name: %s with ID # %s added to the list." %[data.right(-18), id])
			return
		return
	
	if type == Message.LOBBY_LIST:
		if data == "":
			var e : PackedStringArray
			print("Lobby list is empty!")
			lobby_list_received.emit(e)
			return
		else:
			var lobby_list_arr = data.split(" ", false)
			print("Lobby list received!")
			lobby_list_received.emit(lobby_list_arr)
			return
	
	if type == Message.LEFT_LOBBY:
		if User.peers.has(id):
			User.peers.erase(id)
			some_one_left_lobby.emit(data)
			print("Peer name: %s with ID # %s erased from the list" %[data, id])
		return
	
	if type == Message.LOBBY_MESSAGE:
		print("Lobby message received!")
		var arr = data.split("***", true, 1)
		var user_name = arr[0]
		var message = arr[1]
		lobby_messsage_received.emit(message, user_name)
		return
	
	if type == Message.GAME_STARTING:
		var string = data.get_slice(str(User.ID), 1)
		if not string == "":
			game_start_received.emit(string)
		return
	
	if type == Message.MAP_SEED:
		map_seed_received.emit(data.to_int())
		return false
	
	if type == Message.LEFT_GAME:
		if User.peers.has(id):
			User.peers.erase(id)
			some_one_left_game.emit(id)
			print("Peer name: %s with ID # %s left the game" %[data, id])
		return

	if type == Message.SPAWN_POSITIONS:
		var dict: Dictionary = str_to_var(data)
		spawn_positions_received.emit(dict)
		return 
	if type == Message.AI_SEED:
		ai_seed = str_to_var(data)
		return

	return false

func is_client_connected() -> bool:
	return client_connected

func send_user_name(_name : String):
	send_msg(Message.USER_INFO, 0, _name)

func request_lobby_list():
	send_msg(Message.LOBBY_LIST, 0, "")

func request_join_lobby(lobby_id : String):
	send_msg(Message.JOIN_LOBBY, 0, lobby_id)

func request_new_lobby(_name : String):
	send_msg(Message.NEW_LOBBY, 0, _name)

func send_chat_msg(message : String, user_name : String):
	var _message : String = user_name + "***" + message
	send_msg(Message.LOBBY_MESSAGE, 0 , _message)

func send_msg(type: int, id:int, data:String) -> int:
	return ws.send_text(JSON.stringify({"type": type, "id": id, "data": data}))

func send_left_info(lobby_name : String):
	send_msg(Message.LEFT_LOBBY, 0, lobby_name)

func send_start_game(lobby_name : String):
	send_msg(Message.START_GAME, 0, lobby_name)

func send_offer(type: String, sdp: String, id):
	send_msg(Message.OFFER, 0, type + "***" + sdp + "***" + str(id))

func send_answer(type: String, sdp: String, id):
	send_msg(Message.ANSWER, 0, type + "***" + sdp + "***" + str(id))

func send_ice(media: String, index: int, _name: String, id):
	send_msg(Message.ICE, 0, media + "***" + str(index) + "***" + _name + "***" + str(id))

func send_game_starting():
	send_msg(Message.GAME_STARTING, User.ID, "")

func send_map_seed(map_seed: int):
	send_msg(Message.MAP_SEED, 0, str(map_seed))	

func send_left_game(lobby_name: String):
	send_msg(Message.LEFT_GAME, 0, lobby_name)
