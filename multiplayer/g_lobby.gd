extends Node

@warning_ignore("unused_signal")
signal connection_status_changed(to:MultiplayerPeer.ConnectionStatus)

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
	if p and !multiplayer.is_server(): connection_status = p.get_connection_status()


func host_parse_port(port_string:String="") -> bool:
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
			multiplayer.peer_connected.connect(on_peer_connected)
			multiplayer.peer_disconnected.connect(remove_player)
			#multiplayer.peer_disconnected.connect()
			on_peer_connected(1)
			
			# This could be on a button, but that's not needed right now
			#if !has_started: rpc_start_game.rpc()
			
			DisplayServer.window_set_title.call_deferred("hosting")
			
			return true
	return false


func join_parse_port(address:String) -> bool:
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
			multiplayer.peer_disconnected.connect(remove_player)
			multiplayer.server_disconnected.connect(quit)
			
			DisplayServer.window_set_title.call_deferred(str(address, ":", port))
			return true
	return false


func on_peer_connected(id:int) -> void:
	if players.get(id): return
	
	# send current players to the new peer
	for p : int in players:
		rpc_add_player.rpc_id(id, p)
	
	rpc_add_player.rpc(id) # add the peer's player for everyone else
	
	Surfaces.on_peer_connected(id)

@rpc("call_local")
func rpc_add_player(id:int) -> void:
	if players.get(id):
		print("attempted to add duplicate player " + str(id))
		return
	
	var player : Dictionary = {
		"id" = id,
		"nickname" = "Nullevoy" if id == 1 else "fuckass bum",
		"color" = Color.GRAY,
	}
	players[id] = player
	
	HUD.chat.add_message(tr("msg_player_connected") % player.nickname)


func start_game() -> void:
	if players.is_empty(): rpc_add_player(1)
	Surfaces.on_game_started()

func quit() -> void:
	## ffs. 
	Util.check_disconnect(multiplayer.peer_disconnected, remove_player)
	Util.check_disconnect(multiplayer.peer_connected, on_peer_connected)
	Util.check_disconnect(multiplayer.server_disconnected, quit)
	
	multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	
	players.clear()
	Surfaces.clear()

func remove_player(id:int) -> void: 
	if players.has(id):
		HUD.chat.add_message(tr("msg_player_disconnected") % players[id].nickname)
		players.erase(id)

func local_player() -> Dictionary:
	return players.get(multiplayer.get_unique_id())

func get_colored_name(id:int) -> String:
	return str("[color=", players[id].color.to_html(false), "]", players[id].nickname, "[/color]")
