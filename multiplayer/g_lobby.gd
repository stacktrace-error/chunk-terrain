extends Node

@warning_ignore("unused_signal")
signal connection_status_changed(to:MultiplayerPeer.ConnectionStatus)
signal peer_disconnected(id:int)

var connection_status : MultiplayerPeer.ConnectionStatus:
	set(x):
		if(connection_status != x):
			connection_status = x
			connection_status_changed.emit(x)

var players : Dictionary[int, Dictionary] = {}

const default_port : int = 13500

func _ready() -> void:
	var args : Dictionary[String, String] = Util.launch_args
	if args.has("host"):
		host_parse_port(args["host"])
	elif args.has("join"): 
		join_parse_port(args["join"])

func _process(_delta: float) -> void:
	var p : MultiplayerPeer = multiplayer.multiplayer_peer
	if p is ENetMultiplayerPeer and !multiplayer.is_server(): connection_status = p.get_connection_status()


func host_parse_port(port_string:String="") -> bool:
	Settings.write_setting("last_host_port", port_string)
	
	var port : int = default_port
	if !port_string.is_empty(): port = port_string.to_int()
	return host(port)

func host(port:int=default_port) -> bool:
	var peer : ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var error : Error = peer.create_server(port)
	match error:
		ERR_CANT_CREATE: ErrorPopup.show_with(str("Couldn't create server with port ", port, "."))
		ERR_ALREADY_IN_USE: ErrorPopup.show_with("Multiplayer peer already in use.")
		OK:
			multiplayer.multiplayer_peer = peer
			multiplayer.peer_disconnected.connect(on_peer_disconnected)
			send_player()
			
			DisplayServer.window_set_title.call_deferred("hosting")
			
			return true
	return false


func join_parse_port(address:String) -> bool:
	Settings.write_setting("last_join_ip", address)
	
	var split : PackedStringArray = address.rsplit(":", false, 1)
	
	if split.size() > 1: return join(split[0], split[1].to_int())
	return join(address, default_port)

func join(address:String="localhost", port:int=default_port) -> bool:
	quit()
	
	var peer : ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var error : Error = peer.create_client(address, port)
	match error:
		ERR_CANT_CREATE: ErrorPopup.show_with(str("Couldn't create client for ", address, ":", port, "."))
		ERR_ALREADY_IN_USE: ErrorPopup.show_with("Multiplayer peer already in use.")
		OK:
			multiplayer.multiplayer_peer = peer
			multiplayer.connected_to_server.connect(send_player)
			multiplayer.server_disconnected.connect(quit)
			multiplayer.peer_disconnected.connect(on_peer_disconnected)
			
			DisplayServer.window_set_title.call_deferred(str(address, ":", port))
			return true
	return false


func send_player() -> void:
	rpc_send_player.rpc_id(1, Settings.get_player())

@rpc("any_peer", "call_local")
func rpc_send_player(player:Dictionary) -> void:
	if !multiplayer.is_server(): return
	player["id"] = multiplayer.get_remote_sender_id()
	on_player_received(player)

func on_player_received(player:Dictionary) -> void:
	if players.get(player.id): return
	
	# send current players to the new peer
	for p : Dictionary in players.values():
		rpc_add_player.rpc_id(player.id, p)
	
	rpc_add_player.rpc(player) # add the peer's player for everyone else
	
	Surfaces.on_peer_connected(player.id)

@rpc("call_local")
func rpc_add_player(player:Dictionary) -> void:
	if players.get(player.id):
		print("attempted to add duplicate player " + player.id)
		return
	players[player.id] = player
	
	HUD.chat.add_message(tr("msg_player_connected") % player.nickname)


func start_game() -> void:
	if players.is_empty(): send_player()
	Surfaces.on_game_started()

func quit() -> void:
	## ffs. 
	Util.check_disconnect(multiplayer.peer_disconnected, on_peer_disconnected)
	Util.check_disconnect(multiplayer.connected_to_server, send_player)
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
