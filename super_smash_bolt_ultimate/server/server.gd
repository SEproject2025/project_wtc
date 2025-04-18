extends Node

enum Message {USER_INFO, LOBBY_LIST , NEW_LOBBY, JOIN_LOBBY, LEFT_LOBBY, LOBBY_MESSAGE, \
START_GAME, OFFER, ANSWER, ICE, GAME_STARTING, HOST, MAP_SEED, LEFT_GAME, SPAWN_POSITIONS, AI_SEED, \
GENERATE_SEED, SPECTATOR, RESTART_LOBBY, REJOINING_LOBBY}

enum LobbyState {NOT_STARTED, STARTED}

var server = TCPServer.new()
var hard_coded_port = 9999
var peers : Dictionary = {}
var lobbies = []
var to_remove_lobbys = []
var to_remove_peers = []

# signal profanity_check_completed(result: bool) # COMMENT OUT PROFANITY SIGNAL

class Peer extends RefCounted:
	var id : = -1
	var ws = WebSocketPeer.new()
	var user_name : String = ""
	var is_host : bool = false
	var is_spectator: bool = false

	func _init(peer_id, tcp):
		id = peer_id
		var error = ws.accept_stream(tcp)
		if error != OK:
			print("ERROR! Can not accept stream from a connection request!")
		else:
			print("Peer connection successfully accepted!")

	func send_msg(type:int, id:int, data:=""):
		return ws.send_text(JSON.stringify({"type": type,"id": id,"data": data,}))

	func is_ws_open() -> bool:
		return ws.get_ready_state() == WebSocketPeer.STATE_OPEN


class Lobby extends RefCounted:
	var peers = []
	var sealed : bool = false
	var _name : String = ""
	var state : LobbyState = LobbyState.NOT_STARTED
	var seed : int = RandomNumberGenerator.new().randi()
	var host_id: int

	func _init(_host_id : int, _lobby_name : String):
		_name = _lobby_name
		host_id = _host_id


func _init():
	var error = server.listen(hard_coded_port)
	if error != OK:
		print("\nERROR! Can not create server! ERROR CODE = %d" % error)
	else:
		print("\n\nServer created successfully!")

func _process(delta):
	poll()
	clean_up()

func poll():
	if server.is_connection_available():
		var id = randi() % (1 << 31)
		peers[id] = Peer.new(id, server.take_connection())

	for p in peers.values():
		p.ws.poll()

		while p.is_ws_open() and p.ws.get_available_packet_count():
			# var parse_result = await parse_msg(p) # REMOVE AWAIT - parse_msg is not async anymore
			var parse_result = parse_msg(p) # MODIFIED: Remove await
			if parse_result:
				pass
			else:
				print("Message received! ERROR can not parse! ")

		if p.ws.get_ready_state() == WebSocketPeer.STATE_CLOSED:
			print("Peer %d disconnected from server!" %p.id)
			to_remove_peers.push_back(p)

func parse_msg(peer : Peer) -> bool: # REMOVED: async keyword from function def
	var msg : String = peer.ws.get_packet().get_string_from_utf8()
	if msg == "Test msg!":
		print("Test msg received!")
		return true

	var parsed = JSON.parse_string(msg)
	if not typeof(parsed) == TYPE_DICTIONARY \
	or not parsed.has("type") \
	or not parsed.has("id") \
	or not parsed.has("data"):
		return false

	var accepted_msg = {
	"type": str(parsed.type).to_int(),
	"id": str(parsed.id).to_int(),
	"data": parsed.data
	}

	if not str(accepted_msg.type).is_valid_int() \
	or not str(accepted_msg.id).is_valid_int():
		return false

	var type := str(accepted_msg.type).to_int()
	var src_id := str(accepted_msg.id).to_int()
	var data : String = str(accepted_msg.data)


	if type == Message.GAME_STARTING:
		var current_lobby = find_lobby_by_peer(peer)
		if current_lobby:
			var all_peer_ids : String = ""
			var spawn_positions = [
				Vector2(0, -6),
				Vector2(-40, -6),
				Vector2(-80, -6),
				Vector2(-120, -6),
				Vector2(-160, -6),
				Vector2(-200, -6),
			]
			spawn_positions.slice(0, current_lobby.peers.size()).shuffle()
			var spawn_positions_by_id: Dictionary = {}
			var ai_seed = randi()
			for player in current_lobby.peers:
				all_peer_ids += str(player.id) + "***"
				spawn_positions_by_id[player.id] = spawn_positions.pop_front()

			current_lobby.state = LobbyState.STARTED
			for player in current_lobby.peers:
				player.send_msg(Message.GAME_STARTING, 0 , all_peer_ids)
				player.send_msg(Message.MAP_SEED, 0, str(current_lobby.seed))
				player.send_msg(Message.SPAWN_POSITIONS, 0 , var_to_str(spawn_positions_by_id))
				player.send_msg(Message.AI_SEED, 0 , var_to_str(ai_seed))
		return true

	if type == Message.OFFER:
		var str_arr = data.split("***", true , 2)
		var send_to_id = str_arr[2].to_int()
		var receiver_peer = find_peer_by_id(send_to_id)
		if receiver_peer:
			receiver_peer.send_msg(type, peer.id, data)
			print("Sending received OFFER! to peer %d" %peer.id)
			return true
		else:
			print("ERROR: OFFER received but ID do not match with any peer!")
			return false

	if type == Message.ANSWER:
		var str_arr = data.split("***", true , 2)
		var send_to_id = str_arr[2].to_int()
		var receiver_peer = find_peer_by_id(send_to_id)
		if receiver_peer:
			receiver_peer.send_msg(type, peer.id, data)
			print("Sending received ANSWER! to peer %d" %peer.id)
			return true
		else:
			print("ERROR: ANSWER received but ID do not match with any peer!")
			return false

	if type == Message.ICE:
		var str_arr = data.split("***", true , 3)
		var send_to_id = str_arr[3].to_int()
		var receiver_peer = find_peer_by_id(send_to_id)
		if receiver_peer:
			receiver_peer.send_msg(type, peer.id, data)
			print("Sending received ICE! to peer %d" %peer.id)
			return true
		else:
			print("ERROR: ICE received but ID do not match with any peer!")
			return false

	if type == Message.LEFT_LOBBY or type == Message.LEFT_GAME:
		var lobby = find_lobby_by_name(data)
		if lobby:
			if lobby.peers.size() == 1 or lobby.peers.all(func(p): return p.is_spectator == true or p.id == peer.id):
				to_remove_lobbys.push_back(lobby)
				peer.is_host = false
			elif  lobby.peers.size() > 1:
					var delete_after : Peer
					for lobby_peer in lobby.peers:
							lobby_peer.is_host = false
							if lobby_peer.user_name != peer.user_name:
								if type == Message.LEFT_LOBBY:
									lobby_peer.send_msg(Message.LEFT_LOBBY, peer.id, peer.user_name)
								elif type == Message.LEFT_GAME:
									lobby_peer.send_msg(Message.LEFT_GAME, peer.id, str(peer.id))
							if lobby_peer.user_name == peer.user_name:
								delete_after = lobby_peer

					lobby.peers.erase(delete_after)
					if peer.id == lobby.host_id and type == Message.LEFT_LOBBY:
						lobby.host_id = lobby.peers[0].id
						lobby.peers[0].is_host = true

					for player in lobby.peers:
						player.send_msg(Message.HOST, lobby.host_id, str(lobby.host_id))
		return true

	if type == Message.USER_INFO:
		# create_request(data) # COMMENT OUT PROFANITY REQUEST
		# var profanity_result = await(profanity_check_completed) # COMMENT OUT PROFANITY AWAIT
		# if not profanity_result: # COMMENT OUT PROFANITY CHECK
		peer.send_msg(Message.USER_INFO, peer.id, data)
		peer.user_name = data
		print("User name received! Received name: %s" %data)
		# else: # COMMENT OUT PROFANITY ELSE
		# 	peer.send_msg(Message.USER_INFO, peer.id, "INVALID") # COMMENT OUT PROFANITY INVALID SEND
		return true

	if type == Message.LOBBY_LIST:
		var list : String = ""

		for lobby in lobbies:
			list += lobby._name + " "

		peer.send_msg(Message.LOBBY_LIST, 0, list)
		print("Sending lobby list!")
		return true

	if type == Message.NEW_LOBBY:

		for lobby in lobbies:
			if lobby._name == data:
				print("New lobby request received! Requested name: %s ! ERROR: LOBBY NAME TAKEN!" %data)
				peer.send_msg(Message.NEW_LOBBY, 0, "INVALID")
				return true

		var lobby= Lobby.new(peer.id, data)
		peer.is_host = true
		lobby.peers.push_back(peer)
		lobbies.push_back(lobby)
		peer.ws.send_text(JSON.stringify("FEEDBACK: New lobby name: %s" %data))
		peer.send_msg(Message.NEW_LOBBY, 0, data)
		print("New lobby request received! Requested name: %s" %data)
		return true

	if type == Message.JOIN_LOBBY:
		peer.ws.send_text(JSON.stringify("FEEDBACK: Join lobby name: %s" %data))

		var lobby = find_lobby_by_name(data)
		if lobby:
			peer.send_msg(Message.HOST, lobby.host_id, str(lobby.host_id))
			peer.send_msg(Message.JOIN_LOBBY, peer.id, "LOBBY_INFO" + lobby._name + "***" + str(lobby.state))

			for lobby_player in lobby.peers:
				if peer.id != lobby_player.id:
					lobby_player.send_msg(Message.JOIN_LOBBY, peer.id, "NEW_JOINED_USER_NAME" + peer.user_name)
					peer.send_msg(Message.JOIN_LOBBY, lobby_player.id, "EXISTING_USER_NAME" + lobby_player.user_name)
				else:
					lobby_player.send_msg(Message.REJOINING_LOBBY, peer.id, peer.user_name)
					peer.send_msg(Message.REJOINING_LOBBY, lobby_player.id, lobby_player.user_name)
			if !lobby.peers.any(func(p): return p.id == peer.id):
				lobby.peers.push_back(peer)
			print("Join lobby request received! Requested name: %s" %data)
			return true
		else:
			print("Join lobby request received! Requested name: %s ! ERROR: NO SUCH LOBBY!" %data)
			peer.send_msg(Message.JOIN_LOBBY, 0, "INVALID")
			return true

	if type == Message.LOBBY_MESSAGE:
		for i in lobbies:
			if i.peers.has(peer):
				for j in i.peers:
					# create_request(data) # COMMENT OUT PROFANITY REQUEST
					# var profanity_result = await(profanity_check_completed) # COMMENT OUT PROFANITY AWAIT
					# if not profanity_result: # COMMENT OUT PROFANITY CHECK
						j.send_msg(Message.LOBBY_MESSAGE, 0, data)
					# else: # COMMENT OUT PROFANITY ELSE
					# 	var array = data.split("***", true, 1) # COMMENT OUT PROFANITY RESPONSE
					# 	array[1] = "***" # COMMENT OUT PROFANITY RESPONSE
					# 	j.send_msg(Message.LOBBY_MESSAGE, 0, array[0] + "***" + array[1]) # COMMENT OUT PROFANITY RESPONSE
				return true

	if type == Message.MAP_SEED:
		for i in lobbies:
			if i.peers.has(peer):
				for j in i.peers:
						j.send_msg(Message.MAP_SEED, 0, data)
				return true
	
	if type == Message.GENERATE_SEED:
		var generated_seed = randi()
		for i in lobbies:
			if i.peers.has(peer):
				for j in i.peers:
						j.send_msg(Message.GENERATE_SEED, 0, str(generated_seed))
				return true
				
	if type == Message.SPECTATOR:
		peer.is_spectator = true
		return true
	
	if type == Message.RESTART_LOBBY:
		var lobby = find_lobby_by_name(data)
		if lobby:
			lobby.state = LobbyState.NOT_STARTED
			lobby.seed = RandomNumberGenerator.new().randi()
			for lobby_peer in lobby.peers:
				lobby_peer.send_msg(Message.RESTART_LOBBY, 0, str(lobby.seed) + "***" + str(lobby.state))
			if !lobby.peers.any(func(p): return p.is_host):
				lobby.host_id = lobby.peers[0].id
				lobby.peers[0].is_host = true
				for lobby_peers in lobby.peers:
					lobby_peers.send_msg(Message.HOST, lobby.host_id, str(lobby.host_id))
				
			return true
	
	return false


func clean_up():
	for peer in to_remove_peers:
		peers.erase(peer.id)


	for lobby in to_remove_lobbys:
		lobbies.erase(lobby)

	var temp_arr : Array
	for lobby in lobbies:
		for lobby_player in lobby.peers:
			if not peers.has(lobby_player.id):
				temp_arr.push_back(lobby_player)


	for disconnected_peer in temp_arr:
		var searched_lobby = find_lobby_by_peer(disconnected_peer)
		if searched_lobby:
			if searched_lobby.peers.size() > 2:
				disconnected_peer.is_host = false
				searched_lobby.peers[0].is_host = true
			for peer in searched_lobby.peers:
				if not disconnected_peer == peer:
					peer.send_msg(Message.LEFT_LOBBY, disconnected_peer.id, disconnected_peer.user_name)

		searched_lobby.peers.erase(disconnected_peer)
		if searched_lobby.peers.size() == 0:
			to_remove_lobbys.push_back(searched_lobby)


func find_peer_by_id(id):
	for peer_id in peers.keys():
		if id == peer_id:
			return peers[peer_id]

	return false

func find_lobby_by_peer(peer : Peer):
	for lobby in lobbies:
		for lobby_player in lobby.peers:
			if lobby_player == peer:
				return lobby

	return false

func find_lobby_by_name(lobby_name : String):
	for lobby in lobbies:
		if lobby._name == lobby_name:
			return lobby

	return false


# func create_request(text): # COMMENT OUT ENTIRE FUNCTION
# 	var http_request = HTTPRequest.new()
# 	add_child(http_request)
# 	http_request.request_completed.connect(_request_completed.bind(http_request))
# 	var url = "https://www.purgomalum.com/service/containsprofanity?text=" + text.uri_encode()
# 	var error = http_request.request(url)
# 	if error != OK:
# 		print("ERROR! Can not create request! ERROR CODE = %d" % error)
# 	else:
# 		print("Request created successfully!")

# func _request_completed(result, _response_code, _headers, body, http_request): # COMMENT OUT ENTIRE FUNCTION
# 	if result != 0:
# 		print("ERROR! Can not create request! ERROR CODE = %d" % result)
# 		return

# 	var json = JSON.parse_string(body.get_string_from_utf8())
# 	profanity_check_completed.emit(json)
# 	http_request.queue_free()
