extends Node

signal game_started
signal game_quitted
@warning_ignore("unused_signal")
signal player_ready
signal connection_status_changed(to:MultiplayerPeer.ConnectionStatus)

var connection_status : MultiplayerPeer.ConnectionStatus:
	set(x):
		if(connection_status != x):
			connection_status = x
			connection_status_changed.emit(x)

var players : Dictionary[int, Player] = {}
var has_started : bool

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
			if !has_started: rpc_start_game.rpc()
			
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
	for player : int in players:
		rpc_add_player.rpc_id(id, player)
	
	rpc_add_player.rpc(id) # add the peer's player for everyone else
	
	if has_started: rpc_start_game.rpc_id(id) # tell them the game has started

@rpc("call_local")
func rpc_add_player(id:int) -> void:
	if players.get(id):
		print("attempted to spawn duplicate brain for " + str(id))
		return
	
	var player : Player = Player.new()
	player.name = str(id)
	players[id] = player
	add_child(player)


func quit() -> void:
	## ffs. 
	if multiplayer.peer_disconnected.is_connected(remove_player):
		multiplayer.peer_disconnected.disconnect(remove_player)
	if multiplayer.peer_connected.is_connected(on_peer_connected):
		multiplayer.peer_connected.disconnect(on_peer_connected)
	if multiplayer.server_disconnected.is_connected(quit):
		multiplayer.server_disconnected.disconnect(quit)
	
	multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	
	for child : Node in get_children(): child.free()
	players.clear()
	
	Surfaces.clear()
	has_started = false
	game_quitted.emit()

func remove_player(id:int) -> void:
	if players.has(id):
		players[id].remove()
		players.erase(id)


@rpc("call_local")
func rpc_start_game() -> void:
	if players.is_empty(): on_peer_connected(1)
	if !Surfaces.active_surface: Surfaces.new_game()
	has_started = true
	game_started.emit()

func is_open() -> bool:
	return has_started || multiplayer.multiplayer_peer is ENetMultiplayerPeer


func local_player() -> Player:
	return players.get(multiplayer.get_unique_id(), null)
