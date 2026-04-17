extends Node

@warning_ignore("unused_signal")
signal connection_status_changed(to:MultiplayerPeer.ConnectionStatus)
signal peer_disconnected(id:int)

@warning_ignore("int_as_enum_without_cast")
var connection_status : MultiplayerPeer.ConnectionStatus = 0:
	set(x):
		if(connection_status != x):
			connection_status = x
			connection_status_changed.emit(x)

var players : Dictionary[int, Dictionary] = {}

const default_port : int = 13500


func _ready() -> void:
	var args : Dictionary[String, PackedStringArray] = Util.launch_args
	if args.has("host"): host_parse_port(args["host"][0])
	elif args.has("join"): join_parse_port(args["join"][0])


func _process(_delta: float) -> void:
	var p : MultiplayerPeer = multiplayer.multiplayer_peer
	if p is ENetMultiplayerPeer and !multiplayer.is_server(): connection_status = p.get_connection_status()


func host_parse_port(port_string:String="") -> bool:
	Settings.write("last_host_port", port_string)
	
	var port : int = default_port
	if !port_string.is_empty(): port = port_string.to_int()
	return host(port)
	
func host(port:int=default_port) -> bool:
	(multiplayer as SceneMultiplayer).auth_callback = auth_serverside
	(multiplayer as SceneMultiplayer).peer_authenticating.connect(on_peer_auth_serverside)
	
	var peer : ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var error : Error = peer.create_server(port)
	match error:
		ERR_CANT_CREATE: ErrorPopup.show_with(str("Couldn't create server with port ", port, "."))
		ERR_ALREADY_IN_USE: ErrorPopup.show_with("Multiplayer peer already in use.")
		OK:
			multiplayer.multiplayer_peer = peer
			
			multiplayer.peer_disconnected.connect(on_peer_disconnected)
			#send_player()
			
			DisplayServer.window_set_title.call_deferred("hosting")
			
			return true
	return false


func join_parse_port(address:String) -> bool:
	Settings.write("last_join_ip", address)
	
	var split : PackedStringArray = address.rsplit(":", false, 1)
	
	if split.size() > 1: return join(split[0], split[1].to_int())
	return join(address, default_port)

func join(address:String="localhost", port:int=default_port) -> bool:
	quit()
	
	(multiplayer as SceneMultiplayer).auth_callback = auth_clientside
	(multiplayer as SceneMultiplayer).peer_authenticating.connect(on_peer_auth_clientside)
	
	var peer : ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var error : Error = peer.create_client(address, port)
	match error:
		ERR_CANT_CREATE: ErrorPopup.show_with(str("Couldn't create client for ", address, ":", port, "."))
		ERR_ALREADY_IN_USE: ErrorPopup.show_with("Multiplayer peer already in use.")
		OK:
			DisplayServer.window_set_title.call_deferred(str(address, ":", port))
			
			multiplayer.multiplayer_peer = peer
			
			multiplayer.server_disconnected.connect(quit)
			multiplayer.connected_to_server.connect(on_connected_to_server)
			multiplayer.peer_disconnected.connect(on_peer_disconnected)
			
			@warning_ignore("int_as_enum_without_cast")
			connection_status = 1
			
			return true
	return false

func on_peer_auth_serverside(id:int) -> void:
	multiplayer.send_auth(id, Player.create_as_byte_array())

func on_peer_auth_clientside(id:int) -> void:
	multiplayer.send_auth(id, Player.create_as_byte_array())

@warning_ignore("unused_parameter")
func auth_serverside(id:int, data:PackedByteArray) -> void:
	print("server")
	multiplayer.complete_auth(id)

@warning_ignore("unused_parameter")
func auth_clientside(id:int, data:PackedByteArray) -> void:
	print("client")
	multiplayer.complete_auth(id)

func on_connected_to_server() -> void:
	print("weeee")

@rpc("call_local")
func rpc_add_player(player:Dictionary) -> void:
	if players.get(player.id):
		print(str("attempted to add duplicate player ", player.id))
		return
	players[player.id] = player
	
	HUD.chat.add_message(tr("msg_player_connected") % player.nickname)


func start_game() -> void:
	#if players.is_empty(): send_player()
	Surfaces.on_game_started()

func quit() -> void:
	## ffs. 
	Util.check_disconnect(multiplayer.peer_disconnected, on_peer_disconnected)
	#Util.check_disconnect(multiplayer.connected_to_server, send_player)
	Util.check_disconnect(multiplayer.server_disconnected, quit)
	
	multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	
	players.clear()
	Surfaces.clear()

func on_peer_disconnected(id:int) -> void: 
	if players.has(id):
		peer_disconnected.emit(id)
		HUD.chat.add_message(tr("msg_player_disconnected") % players[id].nickname)
		players.erase(id)

func local_player() -> Dictionary:
	return players.get(multiplayer.get_unique_id())

func get_colored_name(id:int) -> String:
	return str("[color=", players[id].nickname_color, "]", players[id].nickname, "[/color]")
