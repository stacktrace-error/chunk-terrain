extends Node

signal game_started
signal player_ready
signal connection_status_changed(to:MultiplayerPeer.ConnectionStatus)

var peer : ENetMultiplayerPeer = ENetMultiplayerPeer.new()
var connection_status : MultiplayerPeer.ConnectionStatus:
	set(x):
		if(connection_status != x):
			connection_status = x
			connection_status_changed.emit(x)

var players : Dictionary[int, Player] = {}
var has_started : bool

const default_port : int = 13500

func _process(_delta: float) -> void:
	var p : MultiplayerPeer = multiplayer.multiplayer_peer
	if p and !multiplayer.is_server(): connection_status = p.get_connection_status()


func host_parse_port(port_string:String="") -> void:
	var port : int = default_port
	if !port_string.is_empty(): port = port_string.to_int()
	host(port)

func host(port:int=default_port) -> void:
	var error : Error = peer.create_server(port)
	match error:
		ERR_CANT_CREATE: ErrorPopup.show_with(str("Couldn't create server with port ", port, "."))
		ERR_ALREADY_IN_USE: ErrorPopup.show_with("Multiplayer peer already in use.")
		OK:
			multiplayer.multiplayer_peer = peer
			multiplayer.peer_connected.connect(on_peer_connected)
			on_peer_connected(1)
			
			rpc_start_game.rpc()
			
			DisplayServer.window_set_title.call_deferred("hosting")


func join_parse_port(address:String) -> void:
	var split : PackedStringArray = address.rsplit(":", false, 1)	
	
	if split.size() > 1: join(split[0], split[1].to_int())
	else: join(address, default_port)

func join(address:String="localhost", port:int=default_port) -> void:
	var error : Error = peer.create_client(address, port)
	match error:
		ERR_CANT_CREATE: ErrorPopup.show_with(str("Couldn't create client for ", address, ":", port, "."))
		ERR_ALREADY_IN_USE: ErrorPopup.show_with("Multiplayer peer already in use.")
		OK:
			multiplayer.multiplayer_peer = peer
			DisplayServer.window_set_title.call_deferred("joining")
			multiplayer.connected_to_server.connect(func()->void:DisplayServer.window_set_title(str(address, ":", port)))
			


func on_peer_connected(id:int) -> void:
	if !players.is_empty():
		for player : int in players:
			rpc_add_player.rpc_id(id, player)
	rpc_add_player.rpc(id)
	
	if has_started: rpc_start_game.rpc_id(id)

@rpc("authority", "call_local")
func rpc_add_player(id:int) -> void:
	if players.get(id, null):
		print("attempted to spawn duplicate brain for " + str(id))
		return
	var player : Player = preload("res://multiplayer/player.tscn").instantiate()
	player.name = str(id)
	players[id] = player
	add_child(player)


@rpc("authority", "call_local")
func rpc_start_game() -> void:
	has_started = true
	game_started.emit()


func get_player() -> Player:
	return players.get(multiplayer.get_unique_id(), null)
